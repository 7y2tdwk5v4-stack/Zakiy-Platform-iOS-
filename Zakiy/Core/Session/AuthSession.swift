import Foundation
import Observation

/// App-wide auth state. Holds the current Supabase session (if any), persists
/// it to the Keychain, and hands out a valid access token to `APIClient` on
/// demand — refreshing it first if it has expired. The backend's protected
/// endpoints (`@require_auth` in app.py) only need this bearer token; guests
/// simply have `session == nil` and use the app without saved history.
@MainActor
@Observable
final class AuthSession {
    static let shared = AuthSession()

    private(set) var session: SupabaseSession?
    private(set) var isRestoringSession = true

    private let storageKey = "supabase.session"

    var isSignedIn: Bool { session != nil }
    var displayName: String { session?.user.username ?? "طالب" }
    var userId: String? { session?.user.id }

    private init() {
        Task { await restore() }
    }

    private func restore() async {
        defer { isRestoringSession = false }
        guard let data = KeychainHelper.load(key: storageKey),
              let saved = try? JSONDecoder().decode(SupabaseSession.self, from: data) else { return }
        session = saved
        if saved.isExpired {
            await refreshIfNeeded()
        }
    }

    func adopt(_ newSession: SupabaseSession) {
        session = newSession
        if let data = try? JSONEncoder().encode(newSession) {
            KeychainHelper.save(data, key: storageKey)
        }
    }

    func signOut() {
        if let token = session?.accessToken {
            Task { await SupabaseAuthClient.shared.signOut(accessToken: token) }
        }
        session = nil
        KeychainHelper.delete(key: storageKey)
    }

    /// Returns a bearer token guaranteed to be fresh, refreshing first if the
    /// stored session has expired. Returns nil for guests.
    func validAccessToken() async -> String? {
        guard let current = session else { return nil }
        if !current.isExpired { return current.accessToken }
        await refreshIfNeeded()
        return session?.accessToken
    }

    private func refreshIfNeeded() async {
        guard let refreshToken = session?.refreshToken else { return }
        do {
            let refreshed = try await SupabaseAuthClient.shared.refresh(refreshToken: refreshToken)
            adopt(refreshed)
        } catch {
            // Refresh token is no longer valid — fall back to signed-out state.
            session = nil
            KeychainHelper.delete(key: storageKey)
        }
    }
}
