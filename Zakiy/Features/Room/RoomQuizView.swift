import SwiftUI

struct RoomQuizView: View {
    @State var store: RoomStore

    @State private var answers: [QuizAnswer] = []
    @State private var currentIndex = 0
    @State private var remainingSeconds: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentAnswer: QuizAnswer? {
        guard answers.indices.contains(currentIndex) else { return nil }
        return answers[currentIndex]
    }

    var body: some View {
        Group {
            if store.hasFinishedQuiz {
                RoomLeaderboardView(store: store)
            } else {
                quizBody
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("اختبار الغرفة")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            if answers.isEmpty, let quiz = store.quiz {
                answers = quiz.map { QuizAnswer(question: $0, selectedOption: nil) }
            }
            updateRemaining()
        }
        .onReceive(timer) { _ in
            updateRemaining()
            if remainingSeconds <= 0 && !store.hasFinishedQuiz {
                finish()
            }
        }
    }

    private var quizBody: some View {
        VStack(spacing: 0) {
            HStack {
                ProgressView(value: Double(currentIndex + 1), total: Double(max(answers.count, 1)))
                    .tint(Color.zakiyTeal)
                Text(timeString)
                    .font(.zakiyCaption.monospacedDigit())
                    .foregroundStyle(remainingSeconds < 30 ? .red : Color.zakiyTextSecondary)
            }
            .padding(.horizontal, ZakiySpacing.lg)
            .padding(.top, ZakiySpacing.sm)

            ScrollView {
                if let answer = currentAnswer {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        Text("سؤال \(currentIndex + 1) من \(answers.count)")
                            .font(.zakiyCaption)
                            .foregroundStyle(Color.zakiyTextSecondary)
                        Text(answer.question.question)
                            .font(.zakiyTitle)

                        VStack(spacing: ZakiySpacing.sm) {
                            ForEach(answer.question.options, id: \.self) { option in
                                Button {
                                    answers[currentIndex].selectedOption = option
                                } label: {
                                    HStack {
                                        Text(option)
                                        Spacer()
                                        if answer.selectedOption == option {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zakiyTeal)
                                        }
                                    }
                                    .padding(ZakiySpacing.md)
                                    .background(answer.selectedOption == option ? Color.zakiyTeal.opacity(0.2) : Color.zakiyMutedSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(ZakiySpacing.lg)
                }
            }

            HStack {
                if currentIndex > 0 {
                    Button("السابق") { currentIndex -= 1 }
                        .buttonStyle(.zakiySecondary)
                }
                Button(currentIndex == answers.count - 1 ? "تسليم" : "التالي") {
                    if currentIndex == answers.count - 1 {
                        finish()
                    } else {
                        currentIndex += 1
                    }
                }
                .buttonStyle(.zakiyPrimary)
            }
            .padding(ZakiySpacing.lg)
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", max(remainingSeconds, 0) / 60, max(remainingSeconds, 0) % 60)
    }

    private func updateRemaining() {
        guard let startedAt = store.quizStartedAt, let duration = store.durationMinutes else { return }
        let endsAt = startedAt + duration * 60
        remainingSeconds = max(0, Int(endsAt - Date().timeIntervalSince1970))
    }

    private func finish() {
        let score = answers.filter(\.isCorrect).count
        let total = answers.count
        let timeTaken = Int((store.durationMinutes ?? 0) * 60) - remainingSeconds
        let wrongTopics = answers.filter { !$0.isCorrect }.map(\.question.topic)
        store.submitScore(score: score, total: total, timeTaken: max(timeTaken, 0), wrongTopics: wrongTopics)
    }
}

struct RoomLeaderboardView: View {
    @State var store: RoomStore
    @Environment(\.dismiss) private var dismiss

    private var sorted: [RoomParticipant] {
        store.leaderboard.sorted {
            if $0.finished != $1.finished { return $0.finished && !$1.finished }
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.timeTaken < $1.timeTaken
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ZakiySpacing.lg) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.zakiyMustard)
                Text("تم تسليم إجابتك!")
                    .font(.zakiyTitle)
                Text("بانتظار بقية المشاركين")
                    .font(.zakiySubheadline)
                    .foregroundStyle(Color.zakiyTextSecondary)

                VStack(spacing: ZakiySpacing.sm) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, participant in
                        HStack {
                            Text(medal(for: index))
                                .frame(width: 28)
                            InitialsAvatar(name: participant.name, diameter: 32)
                            Text(participant.name).font(.zakiyBody.weight(.semibold))
                            Spacer()
                            if participant.finished {
                                Text("\(participant.score)/\(participant.total)")
                                    .font(.zakiyBody)
                            } else {
                                ProgressView()
                            }
                        }
                        .padding(ZakiySpacing.md)
                        .background(Color.zakiySurface)
                        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
                    }
                }

                Button("رجوع للرئيسية") {
                    store.disconnect()
                    dismiss()
                }
                .buttonStyle(.zakiySecondary)
            }
            .padding(ZakiySpacing.lg)
        }
    }

    private func medal(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)"
        }
    }
}
