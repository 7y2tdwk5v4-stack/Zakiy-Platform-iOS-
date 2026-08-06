import Foundation

enum APIError: LocalizedError {
    case server(String)
    case decoding
    case unauthorized
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .decoding: return "تعذر قراءة رد الخادم"
        case .unauthorized: return "لازم تسجل الدخول"
        case .transport(let message): return message
        }
    }
}

/// Thin REST wrapper around `app.py`'s `/api/*` routes. Every method here
/// maps 1:1 to a Flask route — none of the backend logic is duplicated or
/// reinterpreted client-side.
final class APIClient: Sendable {
    static let shared = APIClient()

    private let session = URLSession(configuration: .default)
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private func url(_ path: String) -> URL {
        AppConfig.apiBaseURL.appendingPathComponent(path)
    }

    private func authorizedRequest(_ path: String, method: String) async -> URLRequest {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        if let token = await AuthSession.shared.validAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await perform(request)
        try Self.checkStatus(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func sendNoContent(_ request: URLRequest) async throws {
        let (data, response) = try await perform(request)
        try Self.checkStatus(response, data: data)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private static func checkStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 503 {
                throw APIError.unauthorized
            }
            let message = (try? JSONDecoder().decode(ErrorPayload.self, from: data))?.error
                ?? "حدث خطأ غير متوقع (\(http.statusCode))"
            throw APIError.server(message)
        }
    }

    private func jsonRequest(_ path: String, method: String = "POST", body: [String: Any] = [:], authorized: Bool = false) async -> URLRequest {
        var request = authorized ? await authorizedRequest(path, method: method) : URLRequest(url: url(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !body.isEmpty || method == "POST" || method == "PATCH" {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    // MARK: - Health

    func health() async throws -> Bool {
        let request = URLRequest(url: url("api/health"))
        let (data, response) = try await perform(request)
        try Self.checkStatus(response, data: data)
        return true
    }

    // MARK: - File upload / extraction

    func upload(fileData: Data, filename: String) async throws -> String {
        var request = URLRequest(url: url("api/upload"))
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        struct UploadResponse: Decodable { let filename: String }
        return try await send(request, as: UploadResponse.self).filename
    }

    func extractText(filename: String) async throws -> String {
        let request = await jsonRequest("api/extract", body: ["filename": filename])
        struct ExtractResponse: Decodable { let text: String }
        return try await send(request, as: ExtractResponse.self).text
    }

    // MARK: - AI features

    func summarize(text: String, lang: String = "ar") async throws -> String {
        let request = await jsonRequest("api/summarize", body: ["text": text, "lang": lang])
        struct SummaryResponse: Decodable { let summary: String }
        return try await send(request, as: SummaryResponse.self).summary
    }

    func generateQuiz(text: String, numQuestions: Int, lang: String = "ar") async throws -> [QuizQuestion] {
        let request = await jsonRequest("api/generate-quiz", body: ["text": text, "num_questions": numQuestions, "lang": lang])
        struct QuizRawResponse: Decodable { let quizRaw: String
            enum CodingKeys: String, CodingKey { case quizRaw = "quiz_raw" }
        }
        let raw = try await send(request, as: QuizRawResponse.self).quizRaw
        return try QuizQuestion.parse(fromModelOutput: raw)
    }

    func chat(message: String, interactionId: String?, context: String?, name: String?, lang: String = "ar") async throws -> ChatReply {
        var body: [String: Any] = ["message": message, "lang": lang]
        if let interactionId { body["interaction_id"] = interactionId }
        if let context { body["context"] = context }
        if let name { body["name"] = name }
        let request = await jsonRequest("api/chat", body: body)
        return try await send(request, as: ChatReply.self)
    }

    func siteHelp(message: String, interactionId: String?, lang: String = "ar") async throws -> ChatReply {
        var body: [String: Any] = ["message": message, "lang": lang]
        if let interactionId { body["interaction_id"] = interactionId }
        let request = await jsonRequest("api/site-help", body: body)
        return try await send(request, as: ChatReply.self)
    }

    // MARK: - Quiz attempts / performance

    @discardableResult
    func recordQuizAttempt(mode: String, score: Int, total: Int, timeTaken: Int, wrongTopics: [String]) async throws -> SessionRating {
        let body: [String: Any] = [
            "mode": mode, "score": score, "total": total,
            "time_taken": timeTaken, "wrong_topics": wrongTopics,
        ]
        let request = await jsonRequest("api/quiz-attempt", body: body, authorized: true)
        struct AttemptResponse: Decodable { let rating: SessionRating }
        return try await send(request, as: AttemptResponse.self).rating
    }

    func performance() async throws -> PerformanceSummary {
        let request = await authorizedRequest("api/performance", method: "GET")
        return try await send(request, as: PerformanceSummary.self)
    }

    // MARK: - Library

    func libraryBooks() async throws -> [LibraryBookSummary] {
        let request = await authorizedRequest("api/library", method: "GET")
        struct Response: Decodable { let books: [LibraryBookSummary] }
        return try await send(request, as: Response.self).books
    }

    func libraryBook(id: String) async throws -> LibraryBookDetail {
        let request = await authorizedRequest("api/library/\(id)", method: "GET")
        return try await send(request, as: LibraryBookDetail.self)
    }

    @discardableResult
    func createLibraryBook(title: String, extractedText: String) async throws -> String {
        let request = await jsonRequest("api/library", body: ["title": title, "extracted_text": extractedText], authorized: true)
        struct Response: Decodable { let id: String }
        return try await send(request, as: Response.self).id
    }

    func renameLibraryBook(id: String, title: String) async throws {
        let request = await jsonRequest("api/library/\(id)", method: "PATCH", body: ["title": title], authorized: true)
        try await sendNoContent(request)
    }

    func deleteLibraryBook(id: String) async throws {
        let request = await authorizedRequest("api/library/\(id)", method: "DELETE")
        try await sendNoContent(request)
    }

    // MARK: - Profile

    func syncProfile(username: String) async throws {
        let request = await jsonRequest("api/profile/sync", body: ["username": username], authorized: true)
        try await sendNoContent(request)
    }

    func updateProfile(patch: [String: Any]) async throws {
        let request = await jsonRequest("api/profile", method: "PATCH", body: patch, authorized: true)
        try await sendNoContent(request)
    }

    func profile(userId: String) async throws -> ProfileDetail {
        let request = await authorizedRequest("api/profile/\(userId)", method: "GET")
        return try await send(request, as: ProfileDetail.self)
    }

    // MARK: - Friends

    func searchFriends(query: String) async throws -> [FriendSearchResult] {
        var components = URLComponents(url: url("api/friends/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        var request = await authorizedRequest("api/friends/search", method: "GET")
        request.url = components.url
        struct Response: Decodable { let results: [FriendSearchResult] }
        return try await send(request, as: Response.self).results
    }

    func sendFriendRequest(toUserId: String) async throws {
        let request = await jsonRequest("api/friends/request", body: ["to_user_id": toUserId], authorized: true)
        try await sendNoContent(request)
    }

    func friendRequests() async throws -> FriendRequestsResponse {
        let request = await authorizedRequest("api/friends/requests", method: "GET")
        return try await send(request, as: FriendRequestsResponse.self)
    }

    func acceptFriendRequest(id: String) async throws {
        let request = await jsonRequest("api/friends/accept", body: ["request_id": id], authorized: true)
        try await sendNoContent(request)
    }

    func rejectFriendRequest(id: String) async throws {
        let request = await jsonRequest("api/friends/reject", body: ["request_id": id], authorized: true)
        try await sendNoContent(request)
    }

    func friends() async throws -> [Friend] {
        let request = await authorizedRequest("api/friends", method: "GET")
        struct Response: Decodable { let friends: [Friend] }
        return try await send(request, as: Response.self).friends
    }

    func removeFriend(userId: String) async throws {
        let request = await authorizedRequest("api/friends/\(userId)", method: "DELETE")
        try await sendNoContent(request)
    }

    func inviteFriend(toUserId: String, roomCode: String, roomType: String) async throws {
        let body: [String: Any] = ["to_user_id": toUserId, "room_code": roomCode, "room_type": roomType]
        let request = await jsonRequest("api/friends/invite", body: body, authorized: true)
        try await sendNoContent(request)
    }

    func sessionInvites() async throws -> [SessionInvite] {
        let request = await authorizedRequest("api/friends/invites", method: "GET")
        struct Response: Decodable { let invites: [SessionInvite] }
        return try await send(request, as: Response.self).invites
    }

    func dismissInvite(id: String) async throws {
        let request = await authorizedRequest("api/friends/invites/\(id)", method: "DELETE")
        try await sendNoContent(request)
    }

    // MARK: - Session archive

    func sessions() async throws -> [ArchivedSession] {
        let request = await authorizedRequest("api/sessions", method: "GET")
        struct Response: Decodable { let sessions: [ArchivedSession] }
        return try await send(request, as: Response.self).sessions
    }

    // MARK: - Rooms

    func createRoom(type: String) async throws -> RoomCreated {
        let request = await jsonRequest("api/room/create", body: ["room_type": type])
        return try await send(request, as: RoomCreated.self)
    }
}

private struct ErrorPayload: Decodable { let error: String }

struct ChatReply: Decodable {
    let reply: String
    let interactionId: String
    enum CodingKeys: String, CodingKey { case reply; case interactionId = "interaction_id" }
}

struct SessionRating: Decodable {
    let stars: Int
    let label: String
    let fast: Bool
}

struct RoomCreated: Decodable {
    let roomCode: String
    let roomType: String
    enum CodingKeys: String, CodingKey { case roomCode = "room_code"; case roomType = "room_type" }
}
