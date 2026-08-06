import Foundation

/// Deployment configuration. The iOS app talks to the exact same Flask/Socket.IO
/// backend and Supabase project as the web app (`app.py` in this repo) — none of
/// that server-side logic is touched here, only these client-side endpoints.
///
/// The three values below are placeholders: this repo does not contain a
/// deployed backend URL or Supabase project keys, so fill them in with your
/// real values before running the app. The Supabase anon/public key is safe
/// to ship in the client (by design, unlike the service-role key used in
/// app.py) — it only grants what your Supabase row-level-security allows.
enum AppConfig {
    /// Base URL of the deployed Flask app (the same server as app.py).
    static let apiBaseURL = URL(string: "https://REPLACE_WITH_YOUR_BACKEND_URL")!

    /// Supabase project URL, e.g. "https://xxxxxxxx.supabase.co".
    static let supabaseURL = URL(string: "https://REPLACE_WITH_YOUR_SUPABASE_URL.supabase.co")!

    /// Supabase anon/public API key (Project Settings → API → anon public).
    static let supabaseAnonKey = "REPLACE_WITH_YOUR_SUPABASE_ANON_KEY"
}
