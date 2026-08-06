import Foundation

/// Room/classroom real-time models. These arrive as loosely-typed JSON
/// dictionaries over the Socket.IO connection (see `ZakiySocket`), so each
/// type parses itself from `[String: Any]` rather than using `Codable`.

struct RoomParticipant: Identifiable, Hashable {
    let sid: String
    let name: String
    let score: Int
    let total: Int
    let finished: Bool
    let timeTaken: Int
    let clientId: String?
    let userId: String?
    let isCoHost: Bool
    let inVoice: Bool
    var id: String { sid }

    init?(json: [String: Any]) {
        guard let sid = json["sid"] as? String, let name = json["name"] as? String else { return nil }
        self.sid = sid
        self.name = name
        self.score = json["score"] as? Int ?? 0
        self.total = json["total"] as? Int ?? 0
        self.finished = json["finished"] as? Bool ?? false
        self.timeTaken = json["time_taken"] as? Int ?? 0
        self.clientId = json["client_id"] as? String
        self.userId = json["user_id"] as? String
        self.isCoHost = json["is_co_host"] as? Bool ?? false
        self.inVoice = json["in_voice"] as? Bool ?? false
    }
}

struct RoomState {
    let roomCode: String
    let roomType: String
    let isHost: Bool
    let quiz: [QuizQuestion]?
    let quizStartedAt: Double?
    let durationMinutes: Double?
    let sharedSummary: String?
    let canManageContent: Bool
    let boardStrokes: [BoardStroke]
    let raisedHandClientIds: [String]
    let classStarted: Bool

    init?(json: [String: Any]) {
        guard let roomCode = json["room_code"] as? String else { return nil }
        self.roomCode = roomCode
        self.roomType = json["room_type"] as? String ?? "quiz"
        self.isHost = json["is_host"] as? Bool ?? false
        if let quizArray = json["quiz"] as? [[String: Any]] {
            self.quiz = quizArray.compactMap { dict -> QuizQuestion? in
                guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
                return try? JSONDecoder().decode(QuizQuestion.self, from: data)
            }
        } else {
            self.quiz = nil
        }
        self.quizStartedAt = json["quiz_started_at"] as? Double
        self.durationMinutes = json["duration_minutes"] as? Double
        self.sharedSummary = json["shared_summary"] as? String
        self.canManageContent = json["can_manage_content"] as? Bool ?? false
        self.boardStrokes = (json["board_strokes"] as? [[String: Any]])?.compactMap(BoardStroke.init(json:)) ?? []
        self.raisedHandClientIds = json["raised_hands"] as? [String] ?? []
        self.classStarted = json["class_started"] as? Bool ?? false
    }
}

struct BoardStroke: Identifiable {
    let id: String
    let raw: [String: Any]

    init?(json: [String: Any]) {
        guard let id = json["id"] as? String else { return nil }
        self.id = id
        self.raw = json
    }
}

struct RaisedHand: Identifiable, Hashable {
    var id: String { clientId }
    let clientId: String
    let name: String

    init?(json: [String: Any]) {
        guard let clientId = json["client_id"] as? String else { return nil }
        self.clientId = clientId
        self.name = json["name"] as? String ?? "طالب"
    }
}

struct RoomChatMessage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let message: String
    let timestamp: Double

    init?(json: [String: Any]) {
        guard let name = json["name"] as? String, let message = json["message"] as? String else { return nil }
        self.name = name
        self.message = message
        self.timestamp = json["ts"] as? Double ?? Date().timeIntervalSince1970
    }
}

enum RoomJSON {
    static func leaderboard(from json: [String: Any]) -> [RoomParticipant] {
        (json["leaderboard"] as? [[String: Any]])?.compactMap(RoomParticipant.init(json:)) ?? []
    }

    static func raisedHands(from json: [String: Any]) -> [RaisedHand] {
        (json["raised"] as? [[String: Any]])?.compactMap(RaisedHand.init(json:)) ?? []
    }

    static func errorMessage(from json: [String: Any]) -> String {
        json["error"] as? String ?? "حدث خطأ غير متوقع"
    }

    static func startedQuiz(from json: [String: Any]) -> (quiz: [QuizQuestion], startedAt: Double, durationMinutes: Double)? {
        guard let quizArray = json["quiz"] as? [[String: Any]],
              let startedAt = json["started_at"] as? Double,
              let duration = json["duration_minutes"] as? Double else { return nil }
        let questions = quizArray.compactMap { dict -> QuizQuestion? in
            guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? JSONDecoder().decode(QuizQuestion.self, from: data)
        }
        return (questions, startedAt, duration)
    }
}
