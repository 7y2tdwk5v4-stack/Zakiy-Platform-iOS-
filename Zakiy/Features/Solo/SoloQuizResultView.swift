import SwiftUI

struct SoloQuizResultView: View {
    let store: SoloSessionStore
    let answers: [QuizAnswer]
    @Environment(AuthSession.self) private var authSession

    @State private var rating: SessionRating?
    @State private var isSubmitting = true
    @State private var errorMessage: String?

    private var score: Int { answers.filter(\.isCorrect).count }
    private var total: Int { answers.count }
    private var timeTaken: Int {
        guard let startedAt = store.startedAt else { return 0 }
        return Int(Date().timeIntervalSince(startedAt))
    }
    private var wrongTopics: [String] { answers.filter { !$0.isCorrect }.map(\.question.topic) }

    var body: some View {
        ScrollView {
            VStack(spacing: ZakiySpacing.xl) {
                ZakiyCard {
                    VStack(spacing: ZakiySpacing.md) {
                        Text("\(score) / \(total)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.zakiyTextPrimary)

                        if isSubmitting {
                            ProgressView()
                        } else if let rating {
                            StarRatingView(stars: rating.stars)
                            Text(rating.label)
                                .font(.zakiyHeadline)
                                .foregroundStyle(Color.zakiyTextPrimary)
                            if rating.fast {
                                ZakiyChip(text: "سريع ⚡️", tint: Color.zakiyTeal.opacity(0.2), foreground: Color.zakiyTeal)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.zakiyCaption)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }
                    }
                }

                if !wrongTopics.isEmpty {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "نقاط تحتاج مراجعة")
                            FlowChips(items: Array(Set(wrongTopics)))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                    ForEach(Array(answers.enumerated()), id: \.offset) { _, answer in
                        ZakiyCard {
                            VStack(alignment: .leading, spacing: ZakiySpacing.xs) {
                                HStack(alignment: .top) {
                                    Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(answer.isCorrect ? Color.zakiyTeal : .red)
                                    Text(answer.question.question)
                                        .font(.zakiySubheadline.weight(.semibold))
                                }
                                Text("إجابتك: \(answer.selectedOption ?? "—")")
                                    .font(.zakiyCaption)
                                    .foregroundStyle(Color.zakiyTextSecondary)
                                if !answer.isCorrect {
                                    Text("الصحيحة: \(answer.question.correctAnswer)")
                                        .font(.zakiyCaption)
                                        .foregroundStyle(Color.zakiyTeal)
                                }
                            }
                        }
                    }
                }

                NavigationLink("رجوع للرئيسية") {
                    HomeView()
                }
                .buttonStyle(.zakiySecondary)
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("النتيجة")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task { await submit() }
    }

    private func submit() async {
        guard authSession.isSignedIn else {
            rating = SoloQuizResultView.localRating(score: score, total: total, timeTaken: timeTaken)
            isSubmitting = false
            return
        }
        do {
            rating = try await APIClient.shared.recordQuizAttempt(
                mode: "solo", score: score, total: total, timeTaken: timeTaken, wrongTopics: wrongTopics
            )
        } catch {
            errorMessage = "تعذر حفظ النتيجة بحسابك، بس هذي نتيجتك"
            rating = SoloQuizResultView.localRating(score: score, total: total, timeTaken: timeTaken)
        }
        isSubmitting = false
    }

    /// Mirrors `compute_session_rating` in app.py for guests, whose results
    /// never reach the backend since `/api/quiz-attempt` requires an account.
    static func localRating(score: Int, total: Int, timeTaken: Int) -> SessionRating {
        guard total > 0 else { return SessionRating(stars: 0, label: "", fast: false) }
        let pct = Double(score) / Double(total)
        let stars: Int
        let label: String
        switch pct {
        case 0.9...: stars = 5; label = "ممتاز! 🌟"
        case 0.75..<0.9: stars = 4; label = "جيد جدًا 👏"
        case 0.6..<0.75: stars = 3; label = "جيد 🙂"
        case 0.4..<0.6: stars = 2; label = "يحتاج مراجعة 📖"
        default: stars = 1; label = "راجع الملخص مرة ثانية 💪"
        }
        let expected = Double(total) * 60
        let fast = timeTaken > 0 && Double(timeTaken) < expected * 0.6 && pct >= 0.6
        return SessionRating(stars: stars, label: label, fast: fast)
    }
}

/// Simple wrapping chip layout for topic lists.
struct FlowChips: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: ZakiySpacing.sm)], alignment: .leading, spacing: ZakiySpacing.sm) {
            ForEach(items, id: \.self) { item in
                ZakiyChip(text: item)
            }
        }
    }
}

#Preview {
    let store = SoloSessionStore()
    store.startedAt = Date().addingTimeInterval(-120)
    let question = QuizQuestion(question: "ما عاصمة السعودية؟", options: ["الرياض", "جدة", "الدمام", "مكة"], correctAnswer: "الرياض", topic: "جغرافيا", explanation: "الرياض هي العاصمة الإدارية والسياسية.")
    return NavigationStack {
        SoloQuizResultView(store: store, answers: [QuizAnswer(question: question, selectedOption: "الرياض")])
    }
    .environment(AuthSession.shared)
}
