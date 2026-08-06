import SwiftUI

struct SoloSummaryView: View {
    @Bindable var store: SoloSessionStore
    @Environment(AuthSession.self) private var authSession

    @State private var numQuestions = 10
    @State private var isGeneratingQuiz = false
    @State private var errorMessage: String?
    @State private var goToQuiz = false
    @State private var showChat = false
    @State private var showPomodoro = false
    @State private var isSavingToLibrary = false
    @State private var savedToLibrary = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        SectionHeader(title: "الملخص", subtitle: store.sourceTitle.isEmpty ? nil : store.sourceTitle)
                        Text(store.summary)
                            .font(.zakiyBody)
                            .foregroundStyle(Color.zakiyTextPrimary)
                            .lineSpacing(6)
                    }
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        SectionHeader(title: "جهّز اختبارك", subtitle: "اختر عدد الأسئلة")
                        Stepper("عدد الأسئلة: \(numQuestions)", value: $numQuestions, in: 5...20, step: 1)

                        Button {
                            Task { await generateQuiz() }
                        } label: {
                            if isGeneratingQuiz {
                                ProgressView().tint(.white)
                            } else {
                                Label("توليد اختبار", systemImage: "questionmark.circle.fill")
                            }
                        }
                        .buttonStyle(.zakiyPrimary)
                        .disabled(isGeneratingQuiz)
                    }
                }

                HStack(spacing: ZakiySpacing.md) {
                    Button { showChat = true } label: {
                        Label("اسأل عن الملف", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .buttonStyle(.zakiySecondary)

                    Button { showPomodoro = true } label: {
                        Label("بومودورو", systemImage: "timer")
                    }
                    .buttonStyle(.zakiySecondary)
                }

                if authSession.isSignedIn {
                    Button {
                        Task { await saveToLibrary() }
                    } label: {
                        Label(savedToLibrary ? "تم الحفظ في مكتبتي" : "حفظ في مكتبتي", systemImage: savedToLibrary ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                    }
                    .buttonStyle(.zakiySecondary)
                    .disabled(isSavingToLibrary || savedToLibrary)
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("الملخص")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToQuiz) {
            SoloQuizView(store: store)
        }
        .sheet(isPresented: $showChat) {
            NavigationStack { SoloChatView(store: store) }
        }
        .sheet(isPresented: $showPomodoro) {
            PomodoroTimerView()
                .presentationDetents([.medium])
        }
    }

    private func generateQuiz() async {
        errorMessage = nil
        isGeneratingQuiz = true
        defer { isGeneratingQuiz = false }
        do {
            store.quiz = try await APIClient.shared.generateQuiz(text: store.extractedText, numQuestions: numQuestions)
            goToQuiz = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveToLibrary() async {
        isSavingToLibrary = true
        defer { isSavingToLibrary = false }
        do {
            let title = store.sourceTitle.isEmpty ? "ملف بدون عنوان" : store.sourceTitle
            try await APIClient.shared.createLibraryBook(title: title, extractedText: store.extractedText)
            savedToLibrary = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let store = SoloSessionStore()
    store.summary = "هذا مثال لملخص قصير يوضح شكل الشاشة."
    return NavigationStack { SoloSummaryView(store: store) }
        .environment(AuthSession.shared)
}
