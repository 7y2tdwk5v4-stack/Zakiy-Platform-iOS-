import SwiftUI

struct ClassroomView: View {
    @State var store: RoomStore
    @State private var showRoster = false
    @State private var showKickedAlert = false
    @State private var hasRaisedHand = false

    private var myClientId: String { ClientIdentity.current }

    var body: some View {
        VStack(spacing: 0) {
            WhiteboardView(store: store, canEdit: store.canManageContent)
                .frame(maxHeight: .infinity)

            controlBar
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("الحصة المباشرة")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showRoster = true } label: {
                    Image(systemName: "person.2.fill")
                }
            }
        }
        .sheet(isPresented: $showRoster) {
            NavigationStack { ClassroomRosterView(store: store) }
        }
        .onChange(of: store.wasKicked) { _, kicked in if kicked { showKickedAlert = true } }
        .alert("تم إخراجك من الحصة", isPresented: $showKickedAlert) { Button("حسنًا") {} }
        .overlay(alignment: .top) {
            if let winner = store.luckyDrawWinnerName {
                Text("🎉 الفائز باللفة: \(winner)")
                    .font(.zakiyHeadline)
                    .padding(ZakiySpacing.md)
                    .background(Color.zakiyMustard)
                    .foregroundStyle(Color.zakiyNavy)
                    .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
                    .padding()
                    .onTapGesture { store.luckyDrawWinnerName = nil }
            }
        }
    }

    private var controlBar: some View {
        HStack(spacing: ZakiySpacing.md) {
            Button {
                hasRaisedHand.toggle()
                store.raiseHand()
            } label: {
                Label(hasRaisedHand ? "خفض اليد" : "رفع اليد", systemImage: hasRaisedHand ? "hand.raised.slash.fill" : "hand.raised.fill")
            }
            .buttonStyle(.zakiySecondary)

            if store.canManageContent {
                Button {
                    store.drawLucky()
                } label: {
                    Label("لفة حظ", systemImage: "sparkles")
                }
                .buttonStyle(.zakiyAccent)
                .disabled(store.raisedHands.isEmpty)

                if !store.boardElements.isEmpty {
                    Button(role: .destructive) {
                        store.clearBoard()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .padding(ZakiySpacing.md)
        .background(Color.zakiySurface)
    }
}

/// Roster sheet — participants, raised hands, and (host-only) mute/kick.
struct ClassroomRosterView: View {
    @State var store: RoomStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if !store.raisedHands.isEmpty {
                Section("رافعين إيدهم") {
                    ForEach(store.raisedHands) { hand in
                        Text(hand.name)
                    }
                }
            }
            Section("المشاركون (\(store.leaderboard.count))") {
                ForEach(store.leaderboard) { participant in
                    HStack {
                        InitialsAvatar(name: participant.name, diameter: 30)
                        Text(participant.name)
                        Spacer()
                        if store.isHost {
                            Menu {
                                Button("كتم إجباري") { store.forceMute(sid: participant.sid) }
                                Button("طرد", role: .destructive) { store.kick(sid: participant.sid) }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            Section {
                Label("الصوت الجماعي غير متاح بهذي النسخة من تطبيق iOS بعد", systemImage: "mic.slash")
                    .font(.zakiyCaption)
                    .foregroundStyle(Color.zakiyTextSecondary)
            }
        }
        .navigationTitle("المشاركون")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("إغلاق") { dismiss() } }
        }
    }
}
