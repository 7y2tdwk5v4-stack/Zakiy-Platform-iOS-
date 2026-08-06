import Foundation

/// One multiple-choice question, matching the JSON shape the backend's
/// `/api/generate-quiz` prompt asks Gemini to produce.
struct QuizQuestion: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let question: String
    let options: [String]
    let correctAnswer: String
    let topic: String
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case question, options, topic, explanation
        case correctAnswer = "correct_answer"
    }

    enum ParseError: LocalizedError {
        case noJSONFound
        var errorDescription: String? { "تعذر فهم الاختبار الراجع من الذكاء الاصطناعي" }
    }

    /// `/api/generate-quiz` returns the model's raw text output in `quiz_raw`.
    /// It's normally a bare JSON array, but LLMs occasionally wrap it in a
    /// ```json code fence — this strips that before decoding.
    static func parse(fromModelOutput raw: String) throws -> [QuizQuestion] {
        guard let start = raw.firstIndex(of: "["), let end = raw.lastIndex(of: "]") else {
            throw ParseError.noJSONFound
        }
        let jsonSlice = raw[start...end]
        let data = Data(jsonSlice.utf8)
        return try JSONDecoder().decode([QuizQuestion].self, from: data)
    }
}

/// A single answer picked while taking a quiz, kept client-side to compute
/// score and per-topic weaknesses before submitting to `/api/quiz-attempt`.
struct QuizAnswer {
    let question: QuizQuestion
    var selectedOption: String?

    var isCorrect: Bool { selectedOption == question.correctAnswer }
}
