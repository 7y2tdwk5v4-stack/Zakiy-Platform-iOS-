import SwiftUI

struct SoloQuizView: View {
    @Bindable var store: SoloSessionStore

    @State private var answers: [QuizAnswer] = []
    @State private var currentIndex = 0
    @State private var isSummaryRevealed = false
    @State private var isSummaryExpanded = false
    @State private var showRevealWarning = false
    @State private var goToResult = false

    private var currentAnswer: QuizAnswer? {
        guard answers.indices.contains(currentIndex) else { return nil }
        return answers[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(currentIndex + 1), total: Double(max(answers.count, 1)))
                .tint(Color.zakiyTeal)
                .padding(.horizontal, ZakiySpacing.lg)
                .padding(.top, ZakiySpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                    summaryDisclosure

                    if let answer = currentAnswer {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            Text("سؤال \(currentIndex + 1) من \(answers.count)")
                                .font(.zakiyCaption)
                                .foregroundStyle(Color.zakiyTextSecondary)

                            Text(answer.question.question)
                                .font(.zakiyTitle)
                                .foregroundStyle(Color.zakiyTextPrimary)

                            VStack(spacing: ZakiySpacing.sm) {
                                ForEach(answer.question.options, id: \.self) { option in
                                    optionRow(option: option, answer: answer)
                                }
                            }

                            if let selected = answer.selectedOption {
                                explanationCard(answer: answer, selected: selected)
                            }
                        }
                    }
                }
                .padding(ZakiySpacing.lg)
            }

            footer
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("الاختبار")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            if answers.isEmpty {
                answers = store.quiz.map { QuizAnswer(question: $0, selectedOption: nil) }
            }
        }
        .navigationDestination(isPresented: $goToResult) {
            SoloQuizResultView(store: store, answers: answers)
        }
        .alert("كشف الملخص أثناء الاختبار؟", isPresented: $showRevealWarning) {
            Button("إلغاء", role: .cancel) {}
            Button("كشف على مسؤوليتي") { isSummaryRevealed = true }
        } message: {
            Text("قد يقلل هذا من استفادتك من الاختبار — الأفضل تحاول تجاوب من فهمك أولاً.")
        }
    }

    private var summaryDisclosure: some View {
        DisclosureGroup("الملخص (مرجع)", isExpanded: $isSummaryExpanded) {
            ZStack(alignment: .topTrailing) {
                Text(store.summary)
                    .font(.zakiySubheadline)
                    .foregroundStyle(Color.zakiyTextSecondary)
                    .blur(radius: isSummaryRevealed ? 0 : 8)

                if !isSummaryRevealed {
                    Button {
                        showRevealWarning = true
                    } label: {
                        Label("كشف", systemImage: "eye.fill")
                    }
                    .buttonStyle(.zakiySecondary)
                }
            }
            .padding(.top, ZakiySpacing.sm)
        }
        .font(.zakiySubheadline.weight(.semibold))
        .padding(ZakiySpacing.md)
        .background(Color.zakiyMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
    }

    private func optionRow(option: String, answer: QuizAnswer) -> some View {
        let isSelected = answer.selectedOption == option
        let isCorrectOption = option == answer.question.correctAnswer
        let hasAnswered = answer.selectedOption != nil

        var background: Color = .zakiyMutedSurface
        if hasAnswered {
            if isCorrectOption { background = Color.zakiyTeal.opacity(0.25) }
            else if isSelected { background = Color.red.opacity(0.15) }
        }

        return Button {
            guard !hasAnswered else { return }
            answers[currentIndex].selectedOption = option
        } label: {
            HStack {
                Text(option)
                    .font(.zakiyBody)
                    .foregroundStyle(Color.zakiyTextPrimary)
                Spacer()
                if hasAnswered && isCorrectOption {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zakiyTeal)
                } else if hasAnswered && isSelected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding(ZakiySpacing.md)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }

    private func explanationCard(answer: QuizAnswer, selected: String) -> some View {
        VStack(alignment: .leading, spacing: ZakiySpacing.xs) {
            Label(selected == answer.question.correctAnswer ? "إجابة صحيحة" : "إجابة غير صحيحة",
                  systemImage: selected == answer.question.correctAnswer ? "checkmark.seal.fill" : "info.circle.fill")
                .font(.zakiySubheadline.weight(.semibold))
                .foregroundStyle(selected == answer.question.correctAnswer ? Color.zakiyTeal : .orange)
            Text(answer.question.explanation)
                .font(.zakiySubheadline)
                .foregroundStyle(Color.zakiyTextSecondary)
        }
        .padding(ZakiySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.zakiyMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
    }

    private var footer: some View {
        HStack {
            if currentAnswer?.selectedOption != nil {
                Button(currentIndex == answers.count - 1 ? "إنهاء الاختبار" : "السؤال التالي") {
                    if currentIndex == answers.count - 1 {
                        goToResult = true
                    } else {
                        currentIndex += 1
                    }
                }
                .buttonStyle(.zakiyPrimary)
            }
        }
        .padding(ZakiySpacing.lg)
    }
}
