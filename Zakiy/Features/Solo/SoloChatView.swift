import SwiftUI

struct ChatBubbleMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct SoloChatView: View {
    @Bindable var store: SoloSessionStore
    @Environment(AuthSession.self) private var authSession
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatBubbleMessage] = []
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        if messages.isEmpty {
                            EmptyStateView(systemImage: "bubble.left.and.bubble.right", title: "اسأل عن أي شي بالملف", message: "مثلاً: لخّص لي الفكرة الرئيسية بالفصل الثاني")
                        }
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
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
                TextField("اكتب سؤالك...", text: $draft, axis: .vertical)
                    .padding(ZakiySpacing.md)
                    .background(Color.zakiyMutedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.pill, style: .continuous))

                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                    }
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .tint(Color.zakiyNavy)
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("اسأل عن الملف")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إغلاق") { dismiss() }
            }
        }
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        messages.append(ChatBubbleMessage(text: text, isUser: true))
        isSending = true
        defer { isSending = false }
        do {
            let reply = try await APIClient.shared.chat(
                message: text,
                interactionId: store.chatInteractionId,
                context: store.chatInteractionId == nil ? store.extractedText : nil,
                name: authSession.isSignedIn ? authSession.displayName : nil
            )
            store.chatInteractionId = reply.interactionId
            messages.append(ChatBubbleMessage(text: reply.reply, isUser: false))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ChatBubble: View {
    let message: ChatBubbleMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(.zakiyBody)
                .foregroundStyle(message.isUser ? .white : Color.zakiyTextPrimary)
                .padding(ZakiySpacing.md)
                .background(message.isUser ? Color.zakiyNavy : Color.zakiyMutedSurface)
                .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack { SoloChatView(store: SoloSessionStore()) }
        .environment(AuthSession.shared)
}
