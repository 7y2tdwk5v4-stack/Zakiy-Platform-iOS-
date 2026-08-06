import Foundation

struct QuizAttempt: Codable, Identifiable, Hashable {
    let id: String?
    let mode: String?
    let score: Int
    let total: Int
    let timeTaken: Int?
    let wrongTopics: [String]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, mode, score, total
        case timeTaken = "time_taken"
        case wrongTopics = "wrong_topics"
        case createdAt = "created_at"
    }

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total)
    }

    var createdDate: Date? {
        guard let createdAt else { return nil }
        return ISO8601DateFormatter.zakiyFlexible.date(from: createdAt)
    }
}

struct WeakTopic: Codable, Identifiable, Hashable {
    var id: String { topic }
    let topic: String
    let count: Int
}

struct PerformanceSummary: Codable {
    let attempts: [QuizAttempt]
    let weakTopics: [WeakTopic]
    let totalStudyMinutes: Int
    let currentStreak: Int
    let longestStreak: Int

    enum CodingKeys: String, CodingKey {
        case attempts
        case weakTopics = "weak_topics"
        case totalStudyMinutes = "total_study_minutes"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
    }
}

/// Lighter performance summary embedded in another student's public profile
/// (`_compute_performance_summary` in app.py), distinct from the full
/// `PerformanceSummary` the owner sees on their own dashboard.
struct ProfilePerformanceSummary: Codable {
    let attemptsCount: Int
    let avgScore: Int
    let totalStudyMinutes: Int
    let currentStreak: Int

    enum CodingKeys: String, CodingKey {
        case attemptsCount = "attempts_count"
        case avgScore = "avg_score"
        case totalStudyMinutes = "total_study_minutes"
        case currentStreak = "current_streak"
    }
}

extension ISO8601DateFormatter {
    /// Supabase timestamps include fractional seconds; the plain
    /// `ISO8601DateFormatter()` fails to parse those without this option.
    static let zakiyFlexible: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
