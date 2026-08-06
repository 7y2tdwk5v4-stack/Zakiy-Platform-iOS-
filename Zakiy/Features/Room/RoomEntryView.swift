import SwiftUI

/// Choice between creating a new room/class and joining one with a code —
/// the entry point for both "غرفة جماعية" and "درس مباشر" from the home screen.
struct RoomEntryView: View {
    let roomType: String // "quiz" or "classroom"
    @Environment(AuthSession.self) private var authSession

    @State private var displayName = ""
    @State private var joinCode = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var activeRoom: (code: String, name: String)?

    private var title: String { roomType == "classroom" ? "درس مباشر" : "غرفة جماعية" }

    var body: some View {
        ScrollView {
            VStack(spacing: ZakiySpacing.xl) {
                VStack(spacing: ZakiySpacing.sm) {
                    Text(title)
                        .font(.zakiyHeroTitle)
                    Text(roomType == "classroom" ? "سبورة، رفع يد، ولفة حظ — كلها بلحظتها" : "ذاكر مع أصدقائك ونافسهم بالنتيجة")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ZakiySpacing.lg)

                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        ZakiyTextField(title: "اسمك", text: $displayName)

                        Button {
                            Task { await createRoom() }
                        } label: {
                            if isCreating {
                                ProgressView().tint(.white)
                            } else {
                                Label("إنشاء غرفة جديدة", systemImage: "plus.circle.fill")
                            }
                        }
                        .buttonStyle(.zakiyPrimary)
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    }
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                        SectionHeader(title: "أو انضم برمز")
                        ZakiyTextField(title: "رمز الغرفة", text: $joinCode)
                            .textInputAutocapitalization(.characters)

                        Button("انضمام") {
                            activeRoom = (joinCode.trimmingCharacters(in: .whitespaces).uppercased(), displayName)
                        }
                        .buttonStyle(.zakiySecondary)
                        .disabled(joinCode.trimmingCharacters(in: .whitespaces).isEmpty || displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if displayName.isEmpty, authSession.isSignedIn { displayName = authSession.displayName }
        }
        .navigationDestination(item: Binding(get: { activeRoom.map { RoomDestination(code: $0.code, name: $0.name) } }, set: { if $0 == nil { activeRoom = nil } })) { destination in
            RoomLobbyView(store: RoomStore(roomCode: destination.code, roomType: roomType, displayName: destination.name))
        }
    }

    private func createRoom() async {
        errorMessage = nil
        isCreating = true
        defer { isCreating = false }
        do {
            let created = try await APIClient.shared.createRoom(type: roomType)
            activeRoom = (created.roomCode, displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct RoomDestination: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }
}

#Preview {
    NavigationStack { RoomEntryView(roomType: "quiz") }
        .environment(AuthSession.shared)
}
