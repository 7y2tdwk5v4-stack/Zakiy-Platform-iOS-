import Foundation

enum FriendStatus: String, Codable {
    case selfProfile = "self"
    case none
    case friends
    case pendingSent = "pending_sent"
    case pendingReceived = "pending_received"
}

struct ProfileLibrarySummary: Codable, Hashable {
    let count: Int
    let titles: [String]
}

struct ProfileFriendEntry: Codable, Identifiable, Hashable {
    let userId: String
    let username: String
    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
    }
}

struct ProfileFriendsSummary: Codable, Hashable {
    let count: Int
    let list: [ProfileFriendEntry]
}

/// Full response of `GET /api/profile/<user_id>` — sections are optional
/// because the backend omits them based on the profile owner's privacy
/// settings (see `include_perf` / `include_lib` / … in app.py).
struct ProfileDetail: Codable {
    let userId: String
    let username: String
    let isOwner: Bool
    let friendStatus: FriendStatus
    let isPrivate: Bool
    let bio: String?
    let schoolName: String?
    let showPerformance: Bool?
    let showLibrary: Bool?
    let showArchive: Bool?
    let showFriends: Bool?
    let performance: ProfilePerformanceSummary?
    let library: ProfileLibrarySummary?
    let archive: [ArchivedSession]?
    let friends: ProfileFriendsSummary?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case isOwner = "is_owner"
        case friendStatus = "friend_status"
        case isPrivate = "is_private"
        case bio
        case schoolName = "school_name"
        case showPerformance = "show_performance"
        case showLibrary = "show_library"
        case showArchive = "show_archive"
        case showFriends = "show_friends"
        case performance, library, archive, friends
    }
}

struct FriendSearchResult: Codable, Identifiable, Hashable {
    let userId: String
    let username: String
    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
    }
}

struct Friend: Codable, Identifiable, Hashable {
    let userId: String
    let username: String
    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
    }
}

struct FriendRequestItem: Codable, Identifiable, Hashable {
    let id: String
    let senderId: String?
    let receiverId: String?
    let createdAt: String?
    let username: String

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case createdAt = "created_at"
        case username
    }
}

struct FriendRequestsResponse: Codable {
    let incoming: [FriendRequestItem]
    let outgoing: [FriendRequestItem]
}

struct SessionInvite: Codable, Identifiable, Hashable {
    let id: String
    let roomCode: String
    let roomType: String
    let fromUserId: String?
    let fromUsername: String?
    let toUserId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case roomCode = "room_code"
        case roomType = "room_type"
        case fromUserId = "from_user_id"
        case fromUsername = "from_username"
        case toUserId = "to_user_id"
        case createdAt = "created_at"
    }
}
