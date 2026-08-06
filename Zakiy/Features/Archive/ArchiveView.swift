import SwiftUI

struct ArchiveView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var sessions: [ArchivedSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !authSession.isSignedIn {
                SignedOutPlaceholder(feature: "أرشيف جلساتك")
            } else if isLoading {
                LoadingView()
            } else if sessions.isEmpty {
                EmptyStateView(systemImage: "archivebox", title: "لا يوجد جلسات محفوظة", message: "جلسات الغرف الجماعية والدروس المباشرة اللي تشارك فيها بتظهر هنا")
            } else {
                List(sessions) { session in
                    NavigationLink(value: session) {
                        ArchiveRow(session: session)
                    }
                }
                .listStyle(.plain)
                .refreshable { await load() }
                .navigationDestination(for: ArchivedSession.self) { session in
                    ArchiveDetailView(session: session)
                }
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("الأرشيف")
        .task { await load() }
        .overlay(alignment: .top) {
            if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                    .padding()
            }
        }
    }

    private func load() async {
        guard authSession.isSignedIn else { return }
        isLoading = true
        do {
            sessions = try await APIClient.shared.sessions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ArchiveRow: View {
    let session: ArchivedSession

    var body: some View {
        HStack(spacing: ZakiySpacing.md) {
            Image(systemName: session.roomType == "classroom" ? "pencil.and.outline" : "person.2.fill")
                .foregroundStyle(Color.zakiyNavy)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.roomType == "classroom" ? "درس مباشر" : "غرفة جماعية")
                    .font(.zakiyBody.weight(.semibold))
                HStack(spacing: 6) {
                    if let code = session.roomCode {
                        Text(code).font(.zakiyCaption).foregroundStyle(Color.zakiyTextSecondary)
                    }
                    if let host = session.hostName {
                        Text("· الهوست: \(host)").font(.zakiyCaption).foregroundStyle(Color.zakiyTextSecondary)
                    }
                }
            }
            Spacer()
            Text("\(session.participants?.count ?? 0)")
                .font(.zakiyCaption)
                .foregroundStyle(Color.zakiyTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct ArchiveDetailView: View {
    let session: ArchivedSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.sm) {
                        SectionHeader(title: session.roomType == "classroom" ? "درس مباشر" : "غرفة جماعية", subtitle: session.roomCode)
                        if let host = session.hostName {
                            Text("الهوست: \(host)").font(.zakiySubheadline).foregroundStyle(Color.zakiyTextSecondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                    SectionHeader(title: "المشاركون")
                    ForEach(sortedParticipants) { participant in
                        ZakiyCard {
                            HStack {
                                InitialsAvatar(name: participant.name ?? "؟", diameter: 32)
                                VStack(alignment: .leading) {
                                    HStack(spacing: 4) {
                                        Text(participant.name ?? "طالب").font(.zakiyBody.weight(.semibold))
                                        if participant.isHost == true {
                                            Image(systemName: "crown.fill").foregroundStyle(Color.zakiyMustard).font(.caption)
                                        }
                                    }
                                    if let score = participant.score, let total = participant.total {
                                        Text("\(score) / \(total)").font(.zakiyCaption).foregroundStyle(Color.zakiyTextSecondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("تفاصيل الجلسة")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedParticipants: [ArchivedParticipant] {
        (session.participants ?? []).sorted { ($0.score ?? 0) > ($1.score ?? 0) }
    }
}

#Preview {
    NavigationStack { ArchiveView() }
        .environment(AuthSession.shared)
}
