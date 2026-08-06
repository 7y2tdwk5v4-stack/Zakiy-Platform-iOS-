import Foundation
import Observation

/// Drives one group-room / live-class real-time session over `ZakiySocket`,
/// mirroring the room state kept server-side in `rooms[room_code]` (app.py).
/// Created once per room and shared down the room's whole navigation branch.
@MainActor
@Observable
final class RoomStore {
    let roomCode: String
    let roomType: String
    let displayName: String

    private let socket = ZakiySocket()

    var connectionState: ZakiySocket.ConnectionState = .disconnected
    var isHost = false
    var canManageContent = false
    var leaderboard: [RoomParticipant] = []
    var quiz: [QuizQuestion]?
    var quizStartedAt: Double?
    var durationMinutes: Double?
    var sharedSummary: String?
    var chatMessages: [RoomChatMessage] = []
    var boardElements: [BoardElement] = []
    var raisedHands: [RaisedHand] = []
    var classStarted = false
    var joinError: String?
    var wasKicked = false
    var typingNames: Set<String> = []
    var luckyDrawWinnerName: String?

    /// Set once the local participant finishes and submits their score —
    /// used to know whether to show the quiz or the "waiting for others"
    /// leaderboard view.
    var hasFinishedQuiz = false

    init(roomCode: String, roomType: String, displayName: String) {
        self.roomCode = roomCode
        self.roomType = roomType
        self.displayName = displayName
        registerHandlers()
    }

    func connect() {
        socket.onStateChange = { [weak self] state in
            self?.connectionState = state
            if state == .connected {
                self?.joinRoom()
            }
        }
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    private func joinRoom() {
        Task {
            let token = await AuthSession.shared.validAccessToken()
            socket.emit("join_room", [
                "room_code": roomCode,
                "name": displayName,
                "client_id": ClientIdentity.current,
                "token": token ?? "",
            ])
        }
    }

    // MARK: - Host / co-host actions

    func startQuiz(quiz: [QuizQuestion], durationMinutes: Double) {
        guard let data = try? JSONEncoder().encode(quiz),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        socket.emit("start_quiz", ["room_code": roomCode, "quiz": array, "duration_minutes": durationMinutes])
    }

    func shareSummary(_ summary: String) {
        socket.emit("share_summary", ["room_code": roomCode, "summary": summary])
    }

    func grantPermission(sid: String) {
        socket.emit("grant_permission", ["room_code": roomCode, "sid": sid])
    }

    func revokePermission(sid: String) {
        socket.emit("revoke_permission", ["room_code": roomCode, "sid": sid])
    }

    func kick(sid: String) {
        socket.emit("kick_participant", ["room_code": roomCode, "sid": sid])
    }

    func startClass() {
        socket.emit("start_class", ["room_code": roomCode])
    }

    func forceMute(sid: String) {
        socket.emit("force_mute_participant", ["room_code": roomCode, "sid": sid])
    }

    func drawLucky() {
        socket.emit("lucky_draw", ["room_code": roomCode])
    }

    // MARK: - Everyone

    func raiseHand() {
        socket.emit("raise_hand", ["room_code": roomCode])
    }

    func sendChat(_ message: String) {
        socket.emit("chat_message", ["room_code": roomCode, "message": message])
    }

    func setTyping(_ isTyping: Bool) {
        socket.emit(isTyping ? "typing" : "stop_typing", ["room_code": roomCode])
    }

    func addBoardElement(_ element: BoardElement) {
        boardElements.append(element)
        socket.emit("board_stroke", ["room_code": roomCode, "stroke": element.asJSON])
    }

    func moveBoardElement(id: String, x: Double, y: Double) {
        guard let index = boardElements.firstIndex(where: { $0.id == id }) else { return }
        boardElements[index].x = x
        boardElements[index].y = y
        socket.emit("board_update_stroke", ["room_code": roomCode, "id": id, "patch": ["x": x, "y": y]])
    }

    func resizeBoardElement(id: String, fontSize: Double) {
        guard let index = boardElements.firstIndex(where: { $0.id == id }) else { return }
        boardElements[index].fontSize = fontSize
        socket.emit("board_update_stroke", ["room_code": roomCode, "id": id, "patch": ["fontSize": fontSize]])
    }

    func clearBoard() {
        boardElements = []
        socket.emit("board_clear", ["room_code": roomCode])
    }

    func submitScore(score: Int, total: Int, timeTaken: Int, wrongTopics: [String]) {
        hasFinishedQuiz = true
        socket.emit("submit_score", [
            "room_code": roomCode, "score": score, "total": total,
            "time_taken": timeTaken, "wrong_topics": wrongTopics,
        ])
    }

    // MARK: - Incoming events

    private func registerHandlers() {
        socket.on("join_error") { [weak self] json in
            self?.joinError = RoomJSON.errorMessage(from: json)
        }
        socket.on("room_state") { [weak self] json in
            self?.applyRoomState(json)
        }
        socket.on("leaderboard_update") { [weak self] json in
            self?.leaderboard = RoomJSON.leaderboard(from: json)
        }
        socket.on("summary_shared") { [weak self] json in
            self?.sharedSummary = json["summary"] as? String
        }
        socket.on("permission_granted") { [weak self] _ in
            self?.canManageContent = true
        }
        socket.on("permission_revoked") { [weak self] _ in
            self?.canManageContent = false
        }
        socket.on("quiz_started") { [weak self] json in
            guard let started = RoomJSON.startedQuiz(from: json) else { return }
            self?.quiz = started.quiz
            self?.quizStartedAt = started.startedAt
            self?.durationMinutes = started.durationMinutes
            self?.hasFinishedQuiz = false
        }
        socket.on("chat_message") { [weak self] json in
            guard let message = RoomChatMessage(json: json) else { return }
            self?.chatMessages.append(message)
        }
        socket.on("user_typing") { [weak self] json in
            guard let name = json["name"] as? String else { return }
            self?.typingNames.insert(name)
        }
        socket.on("user_stop_typing") { [weak self] json in
            guard let name = json["name"] as? String else { return }
            self?.typingNames.remove(name)
        }
        socket.on("kicked") { [weak self] _ in
            self?.wasKicked = true
        }
        socket.on("class_started_event") { [weak self] _ in
            self?.classStarted = true
        }
        socket.on("hands_update") { [weak self] json in
            self?.raisedHands = RoomJSON.raisedHands(from: json)
        }
        socket.on("board_stroke") { [weak self] json in
            guard let strokeDict = json["stroke"] as? [String: Any], let element = BoardElement(json: strokeDict) else { return }
            self?.boardElements.append(element)
        }
        socket.on("board_update_stroke") { [weak self] json in
            guard let id = json["id"] as? String, let patch = json["patch"] as? [String: Any] else { return }
            guard let self, let index = self.boardElements.firstIndex(where: { $0.id == id }) else { return }
            if let x = patch["x"] as? Double { self.boardElements[index].x = x }
            if let y = patch["y"] as? Double { self.boardElements[index].y = y }
            if let fontSize = patch["fontSize"] as? Double { self.boardElements[index].fontSize = fontSize }
        }
        socket.on("board_clear") { [weak self] _ in
            self?.boardElements = []
        }
        socket.on("lucky_draw_result") { [weak self] json in
            self?.luckyDrawWinnerName = json["winner_name"] as? String
        }
    }

    private func applyRoomState(_ json: [String: Any]) {
        guard let state = RoomState(json: json) else { return }
        isHost = state.isHost
        canManageContent = state.canManageContent
        quiz = state.quiz
        quizStartedAt = state.quizStartedAt
        durationMinutes = state.durationMinutes
        sharedSummary = state.sharedSummary
        boardElements = state.boardStrokes.compactMap { BoardElement(json: $0.raw) }
        classStarted = state.classStarted
    }
}
