import SwiftUI

@main
struct ZakiyApp: App {
    @State private var authSession = AuthSession.shared
    @AppStorage("zakiy.colorScheme") private var storedColorScheme: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch storedColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environment(authSession)
                .preferredColorScheme(preferredColorScheme)
                .tint(Color.zakiyMustard)
        }
    }
}

/// Switches between the splash/loading state, the auth flow, and the signed-in
/// app shell depending on whether a Supabase session was restored from the
/// Keychain. Guests can tap through without signing in at all.
struct RootContainerView: View {
    @Environment(AuthSession.self) private var authSession
    @AppStorage("zakiy.continuedAsGuest") private var continuedAsGuest = false

    var body: some View {
        Group {
            if authSession.isRestoringSession {
                SplashView()
            } else if authSession.isSignedIn || continuedAsGuest {
                RootView()
            } else {
                WelcomeView(continuedAsGuest: $continuedAsGuest)
            }
        }
        .animation(.easeInOut, value: authSession.isRestoringSession)
        .animation(.easeInOut, value: authSession.isSignedIn)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.zakiyBackground.ignoresSafeArea()
            ZakiyLogo(size: .zakiyHeroTitle)
        }
    }
}
