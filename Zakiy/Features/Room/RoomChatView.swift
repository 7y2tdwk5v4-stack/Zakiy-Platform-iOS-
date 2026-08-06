import SwiftUI

struct RoomChatView: View {
    @State var store: RoomStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ZakiySpacing.sm) {
                        if store.chatMessages.isEmpty {
                            EmptyStateView(systemImage: "bubble.left.and.bubble.right", title: "ما فيه رسائل بعد")
                        }
                        ForEach(store.chatMessages) { message in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.name)
                                    .font(.zakiyCaption.weight(.semibold))
                                    .foregroundStyle(Color.zakiyTeal)
                                Text(message.message)
                                    .font(.zakiyBody)
                            }
                            .padding(ZakiySpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.zakiyMutedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
                            .id(message.id)
                        }
                        if !store.typingNames.isEmpty {
                            Text("\(store.typingNames.joined(separator: "، ")) يكتب...")
                                .font(.zakiyCaption)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }
                    }
                    .padding(ZakiySpacing.lg)
                }
                .onChange(of: store.chatMessages.count) {
                    if let last = store.chatMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: ZakiySpacing.sm) {
                TextField("رسالتك...", text: $draft)
                    .padding(ZakiySpacing.md)
                    .background(Color.zakiyMutedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.pill, style: .continuous))
                    .onChange(of: draft) { _, newValue in
                        store.setTyping(!newValue.isEmpty)
                    }

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30))
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                .tint(Color.zakiyNavy)
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("شات الغرفة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إغلاق") { dismiss() }
            }
        }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        store.sendChat(text)
        store.setTyping(false)
        draft = ""
    }
}
