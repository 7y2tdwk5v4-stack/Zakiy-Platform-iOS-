import SwiftUI
import UniformTypeIdentifiers

struct RoomLobbyView: View {
    @State var store: RoomStore

    @State private var showChat = false
    @State private var showKickedAlert = false
    @State private var showJoinErrorAlert = false
    @State private var goToQuiz = false
    @State private var goToClass = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                header

                if store.roomType == "quiz", store.canManageContent {
                    RoomHostContentPanel(store: store)
                } else if store.roomType == "classroom", store.canManageContent {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "التحكم بالحصة")
                            Button("ابدأ الحصة") { store.startClass() }
                                .buttonStyle(.zakiyPrimary)
                        }
                    }
                } else {
                    ZakiyCard {
                        VStack(spacing: ZakiySpacing.sm) {
                            ProgressView()
                            Text(store.roomType == "classroom" ? "بانتظار المدرّس يبدأ الحصة" : "بانتظار الهوست يجهّز الاختبار")
                                .font(.zakiySubheadline)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                participantsSection
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("غرفة \(store.roomCode)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showChat = true } label: {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
            }
        }
        .sheet(isPresented: $showChat) {
            NavigationStack { RoomChatView(store: store) }
        }
        .onAppear { store.connect() }
        .onDisappear { store.disconnect() }
        .onChange(of: store.wasKicked) { _, kicked in if kicked { showKickedAlert = true } }
        .onChange(of: store.joinError) { _, error in if error != nil { showJoinErrorAlert = true } }
        .onChange(of: store.quizStartedAt) { _, startedAt in if startedAt != nil { goToQuiz = true } }
        .onChange(of: store.classStarted) { _, started in if started { goToClass = true } }
        .navigationDestination(isPresented: $goToQuiz) {
            RoomQuizView(store: store)
        }
        .navigationDestination(isPresented: $goToClass) {
            ClassroomView(store: store)
        }
        .alert("تم إخراجك من الغرفة", isPresented: $showKickedAlert) {
            Button("حسنًا") {}
        }
        .alert("تعذر الانضمام", isPresented: $showJoinErrorAlert) {
            Button("حسنًا") {}
        } message: {
            Text(store.joinError ?? "")
        }
    }

    private var header: some View {
        ZakiyCard {
            VStack(spacing: ZakiySpacing.sm) {
                Text("رمز الغرفة")
                    .font(.zakiyCaption)
                    .foregroundStyle(Color.zakiyTextSecondary)
                Text(store.roomCode)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zakiyTextPrimary)
                    .tracking(4)
                ShareLink(item: "انضم لغرفتي بذكيّ برمز: \(store.roomCode)") {
                    Label("شارك الرمز", systemImage: "square.and.arrow.up")
                }
                .font(.zakiyCaption)

                connectionBadge
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var connectionBadge: some View {
        Group {
            switch store.connectionState {
            case .connected: ZakiyChip(text: "متصل", tint: Color.zakiyTeal.opacity(0.2), foreground: Color.zakiyTeal)
            case .connecting: ZakiyChip(text: "جارٍ الاتصال...")
            case .disconnected: ZakiyChip(text: "غير متصل", tint: .red.opacity(0.15), foreground: .red)
            }
        }
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
            SectionHeader(title: "المشاركون", subtitle: "\(store.leaderboard.count)")
            ForEach(store.leaderboard) { participant in
                ZakiyCard {
                    HStack {
                        InitialsAvatar(name: participant.name, diameter: 32)
                        HStack(spacing: 4) {
                            Text(participant.name).font(.zakiyBody.weight(.semibold))
                            if participant.isCoHost {
                                Image(systemName: "star.fill").font(.caption).foregroundStyle(Color.zakiyMustard)
                            }
                        }
                        Spacer()
                        if store.isHost {
                            hostControls(for: participant)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func hostControls(for participant: RoomParticipant) -> some View {
        Menu {
            if participant.isCoHost {
                Button("سحب صلاحية الرفع") { store.revokePermission(sid: participant.sid) }
            } else {
                Button("منح صلاحية الرفع") { store.grantPermission(sid: participant.sid) }
            }
            Button("طرد", role: .destructive) { store.kick(sid: participant.sid) }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(Color.zakiyTextSecondary)
        }
    }
}

/// Host-only panel to prepare a file → summary → quiz and launch it for
/// everyone in the room (mirrors the solo flow but broadcasts via RoomStore).
private struct RoomHostContentPanel: View {
    let store: RoomStore

    @State private var isPickerPresented = false
    @State private var isBusy = false
    @State private var busyText = ""
    @State private var errorMessage: String?
    @State private var extractedText = ""
    @State private var summary = ""
    @State private var numQuestions = 10
    @State private var durationMinutes = 10.0

    var body: some View {
        ZakiyCard {
            VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                SectionHeader(title: "تجهيز الاختبار", subtitle: "أنت المسؤول عن هذي الغرفة")

                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                if isBusy {
                    HStack { ProgressView(); Text(busyText).font(.zakiySubheadline) }
                } else if summary.isEmpty {
                    Button("رفع ملف PDF") { isPickerPresented = true }
                        .buttonStyle(.zakiyPrimary)
                } else {
                    Text(summary)
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                        .lineLimit(4)

                    Stepper("عدد الأسئلة: \(numQuestions)", value: $numQuestions, in: 5...20)
                    Stepper("مدة الاختبار: \(Int(durationMinutes)) دقيقة", value: $durationMinutes, in: 3...60, step: 1)

                    Button("بدء الاختبار للجميع") {
                        Task { await startQuiz() }
                    }
                    .buttonStyle(.zakiyAccent)
                }
            }
        }
        .fileImporter(isPresented: $isPickerPresented, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): Task { await handlePicked(url: url) }
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
    }

    private func handlePicked(url: URL) async {
        errorMessage = nil
        guard url.startAccessingSecurityScopedResource() else { errorMessage = "تعذر فتح الملف"; return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { errorMessage = "تعذر قراءة الملف"; return }

        do {
            isBusy = true
            busyText = "جارٍ رفع الملف..."
            let filename = try await APIClient.shared.upload(fileData: data, filename: url.lastPathComponent)
            busyText = "جارٍ استخراج النص..."
            extractedText = try await APIClient.shared.extractText(filename: filename)
            busyText = "جارٍ التلخيص..."
            summary = try await APIClient.shared.summarize(text: extractedText)
            store.shareSummary(summary)
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    private func startQuiz() async {
        isBusy = true
        busyText = "جارٍ توليد الاختبار..."
        defer { isBusy = false }
        do {
            let quiz = try await APIClient.shared.generateQuiz(text: extractedText, numQuestions: numQuestions)
            store.startQuiz(quiz: quiz, durationMinutes: durationMinutes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
