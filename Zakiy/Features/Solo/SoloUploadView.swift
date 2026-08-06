import SwiftUI
import UniformTypeIdentifiers

struct SoloUploadView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var store = SoloSessionStore()
    @State private var isPickerPresented = false
    @State private var isLibraryPickerPresented = false
    @State private var phase: Phase = .idle
    @State private var errorMessage: String?
    @State private var goToSummary = false

    private enum Phase: Equatable {
        case idle, uploading, extracting, summarizing
        var isBusy: Bool { self != .idle }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ZakiySpacing.xl) {
                VStack(spacing: ZakiySpacing.sm) {
                    Text("مذاكرة فردية")
                        .font(.zakiyHeroTitle)
                    Text("ارفع ملف PDF وخلّ ذكيّ يلخصه ويسوي منه اختبار")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ZakiySpacing.lg)

                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                ZakiyCard {
                    VStack(spacing: ZakiySpacing.lg) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.zakiyMustard)

                        if phase.isBusy {
                            VStack(spacing: ZakiySpacing.sm) {
                                ProgressView()
                                Text(statusText)
                                    .font(.zakiySubheadline)
                                    .foregroundStyle(Color.zakiyTextSecondary)
                            }
                        } else {
                            Text("PDF فقط")
                                .font(.zakiyCaption)
                                .foregroundStyle(Color.zakiyTextSecondary)

                            Button("اختيار ملف") { isPickerPresented = true }
                                .buttonStyle(.zakiyPrimary)

                            if authSession.isSignedIn {
                                Button("اختيار من مكتبتي") { isLibraryPickerPresented = true }
                                    .buttonStyle(.zakiySecondary)
                            }
                        }
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("مذاكرة فردية")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isPickerPresented, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): Task { await handlePicked(url: url) }
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isLibraryPickerPresented) {
            LibraryPickerView { book in
                store.sourceTitle = book.title
                store.extractedText = book.extractedText
                Task { await summarize() }
            }
        }
        .navigationDestination(isPresented: $goToSummary) {
            SoloSummaryView(store: store)
        }
    }

    private var statusText: String {
        switch phase {
        case .uploading: return "جارٍ رفع الملف..."
        case .extracting: return "جارٍ استخراج النص..."
        case .summarizing: return "جارٍ تلخيص المحتوى..."
        case .idle: return ""
        }
    }

    private func handlePicked(url: URL) async {
        errorMessage = nil
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "تعذر فتح الملف"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "تعذر قراءة الملف"
            return
        }

        store.sourceTitle = url.deletingPathExtension().lastPathComponent

        do {
            phase = .uploading
            let filename = try await APIClient.shared.upload(fileData: data, filename: url.lastPathComponent)
            phase = .extracting
            let text = try await APIClient.shared.extractText(filename: filename)
            store.extractedText = text
            await summarize()
        } catch {
            phase = .idle
            errorMessage = error.localizedDescription
        }
    }

    private func summarize() async {
        errorMessage = nil
        phase = .summarizing
        do {
            store.summary = try await APIClient.shared.summarize(text: store.extractedText)
            store.startedAt = Date()
            phase = .idle
            goToSummary = true
        } catch {
            phase = .idle
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { SoloUploadView() }
        .environment(AuthSession.shared)
}
