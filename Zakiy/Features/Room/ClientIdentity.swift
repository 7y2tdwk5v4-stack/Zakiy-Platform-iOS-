import Foundation

/// A stable per-install identifier the backend uses to recognize the same
/// browser/device across Socket.IO reconnects (`client_id` in app.py), so a
/// brief network drop doesn't cost a participant their host/co-host status
/// or their in-progress quiz state.
enum ClientIdentity {
    static let current: String = {
        let key = "zakiy.clientId"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }()
}
