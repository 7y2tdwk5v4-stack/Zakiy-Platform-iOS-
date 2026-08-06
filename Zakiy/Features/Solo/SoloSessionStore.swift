import Foundation
import Observation

/// Shared state for one solo-study session — from the uploaded file's text,
/// through its summary, to the generated quiz and the student's answers.
/// Created once in `SoloUploadView` and passed down the navigation stack so
/// every screen in the flow (summary, quiz, chat) works off the same file.
@MainActor
@Observable
final class SoloSessionStore {
    var sourceTitle: String = ""
    var extractedText: String = ""
    var summary: String = ""
    var quiz: [QuizQuestion] = []
    var chatInteractionId: String?
    var startedAt: Date?
}
