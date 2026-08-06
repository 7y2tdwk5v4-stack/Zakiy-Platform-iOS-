import Foundation

/// Account payload returned by Supabase's GoTrue auth REST API.
struct SupabaseUser: Codable, Sendable {
    let id: String
    let email: String?
    let userMetadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }

    var username: String? {
        if case .string(let value)? = userMetadata?["username"] { return value }
        return nil
    }
}

struct SupabaseSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }

    var isExpired: Bool {
        Date().timeIntervalSince1970 > expiresAt - 30
    }
}

/// A tiny, dependency-free JSON value used to decode Supabase's freeform
/// `user_metadata` dictionary without pulling in a third-party package.
enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

enum SupabaseAuthError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "رد غير متوقع من خادم الحسابات"
        case .server(let message): return message
        }
    }
}

/// Talks directly to Supabase's Auth (GoTrue) REST API — the same identity
/// provider the web app uses — over plain HTTPS, with no third-party SDK.
/// Only the anon/public key travels with the app; all writes still go
/// through Supabase's own row-level security.
final class SupabaseAuthClient: Sendable {
    static let shared = SupabaseAuthClient()

    private let session = URLSession(configuration: .default)

    private func authURL(_ path: String) -> URL {
        AppConfig.supabaseURL.appendingPathComponent("auth/v1/\(path)")
    }

    private func request(path: String, query: [String: String] = [:], body: [String: Any]) async throws -> SupabaseSession {
        var components = URLComponents(url: authURL(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseAuthError.invalidResponse }

        if !(200...299).contains(http.statusCode) {
            let message = (try? JSONDecoder().decode(SupabaseErrorPayload.self, from: data))?.readableMessage
                ?? "تعذر إتمام الطلب (\(http.statusCode))"
            throw SupabaseAuthError.server(message)
        }

        return try JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func signUp(email: String, password: String, username: String, stage: String?, level: String?) async throws -> SupabaseSession {
        var data: [String: Any] = ["username": username]
        if let stage { data["stage"] = stage }
        if let level { data["level"] = level }
        return try await request(path: "signup", body: ["email": email, "password": password, "data": data])
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await request(path: "token", query: ["grant_type": "password"], body: ["email": email, "password": password])
    }

    func refresh(refreshToken: String) async throws -> SupabaseSession {
        try await request(path: "token", query: ["grant_type": "refresh_token"], body: ["refresh_token": refreshToken])
    }

    func signOut(accessToken: String) async {
        var request = URLRequest(url: authURL("logout"))
        request.httpMethod = "POST"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: request)
    }
}

private struct SupabaseErrorPayload: Codable {
    let error: String?
    let errorDescription: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
    }

    var readableMessage: String? { msg ?? errorDescription ?? error }
}
