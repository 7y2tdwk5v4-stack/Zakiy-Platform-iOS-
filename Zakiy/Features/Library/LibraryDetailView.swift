import SwiftUI

/// Full text of a saved library book, with a shortcut to re-run the solo
/// summarize → quiz flow on it without re-uploading the PDF.
struct LibraryDetailView: View {
    let bookId: String
    let title: String

    @State private var detail: LibraryBookDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var store: SoloSessionStore?
    @State private var goToSummary = false
    @State private var isSummarizing = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
            } else if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                        Button {
                            Task { await reopen(detail: detail) }
                        } label: {
                            if isSummarizing {
                                ProgressView().tint(.white)
                            } else {
                                Label("لخّص وسوّي اختبار من جديد", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.zakiyPrimary)

                        ZakiyCard {
                            Text(detail.extractedText)
                                .font(.zakiyBody)
                                .foregroundStyle(Color.zakiyTextPrimary)
                        }
                    }
                    .padding(ZakiySpacing.lg)
                }
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .navigationDestination(isPresented: $goToSummary) {
            if let store { SoloSummaryView(store: store) }
        }
    }

    private func load() async {
        do {
            detail = try await APIClient.shared.libraryBook(id: bookId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func reopen(detail: LibraryBookDetail) async {
        isSummarizing = true
        defer { isSummarizing = false }
        let newStore = SoloSessionStore()
        newStore.sourceTitle = detail.title
        newStore.extractedText = detail.extractedText
        do {
            newStore.summary = try await APIClient.shared.summarize(text: detail.extractedText)
            newStore.startedAt = Date()
            store = newStore
            goToSummary = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
