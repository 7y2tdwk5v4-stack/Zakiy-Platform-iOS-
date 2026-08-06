import SwiftUI

/// "مساعد ذكيّ" — an AI assistant that explains how to use the app itself,
/// available to everyone (guests included), backed by `/api/site-help`.
struct SiteHelpView: View {
    @State private var messages: [ChatBubbleMessage] = []
    @State private var interactionId: String?
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private let suggestions = [
        "كيف أسوي اختبار من ملف PDF؟",
        "كيف أنشئ غرفة مذاكرة جماعية؟",
        "وش فايدة إنشاء حساب؟",
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        if messages.isEmpty {
                            VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                                EmptyStateView(systemImage: "sparkles", title: "أنا مساعد ذكيّ", message: "اسألني عن أي شي يخص استخدام المنصة")
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        draft = suggestion
                                        Task { await send() }
                                    }
                                    .buttonStyle(.zakiySecondary)
                                }
                            }
                        }
                        ForEach(messages) { message in
                            ChatBubble(message: message).id(message.id)
                        }
                        if let errorMessage {
                            ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                        }
                    }
                    .padding(ZakiySpacing.lg)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: ZakiySpacing.sm) {
                TextField("اسأل عن المنصة...", text: $draft, axis: .vertical)
                    .padding(ZakiySpacing.md)
                    .background(Color.zakiyMutedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.pill, style: .continuous))

                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 30))
                    }
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .tint(Color.zakiyNavy)
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("مساعد ذكيّ")
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        messages.append(ChatBubbleMessage(text: text, isUser: true))
        isSending = true
        defer { isSending = false }
        do {
            let reply = try await APIClient.shared.siteHelp(message: text, interactionId: interactionId)
            interactionId = reply.interactionId
            messages.append(ChatBubbleMessage(text: reply.reply, isUser: false))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { SiteHelpView() }
}
