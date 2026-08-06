import Foundation

struct ArchivedParticipant: Codable, Identifiable, Hashable {
    var id: String { name + (userId ?? "") }
    let name: String?
    let userId: String?
    let score: Int?
    let total: Int?
    let timeTaken: Int?
    let finished: Bool?
    let isHost: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case userId = "user_id"
        case score, total
        case timeTaken = "time_taken"
        case finished
        case isHost = "is_host"
    }
}

struct ArchivedSession: Codable, Identifiable, Hashable {
    let id: String
    let roomCode: String?
    let roomType: String?
    let hostName: String?
    let hostUserId: String?
    let participants: [ArchivedParticipant]?
    let participantUserIds: [String]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case roomCode = "room_code"
        case roomType = "room_type"
        case hostName = "host_name"
        case hostUserId = "host_user_id"
        case participants
        case participantUserIds = "participant_user_ids"
        case createdAt = "created_at"
    }

    var createdDate: Date? {
        guard let createdAt else { return nil }
        return ISO8601DateFormatter.zakiyFlexible.date(from: createdAt)
    }
}
