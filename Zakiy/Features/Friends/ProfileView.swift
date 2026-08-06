import SwiftUI

struct ProfileView: View {
    let userId: String

    @State private var profile: ProfileDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isSendingRequest = false
    @State private var showEdit = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let profile {
                content(profile)
            } else if let errorMessage {
                EmptyStateView(systemImage: "person.crop.circle.badge.exclamationmark", title: "تعذر تحميل البروفايل", message: errorMessage)
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle(profile?.username ?? "البروفايل")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if profile?.isOwner == true {
                ToolbarItem(placement: .primaryAction) {
                    Button("تعديل") { showEdit = true }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let profile { ProfileEditView(profile: profile) { await load() } }
        }
        .task { await load() }
    }

    @ViewBuilder
    private func content(_ profile: ProfileDetail) -> some View {
        ScrollView {
            VStack(spacing: ZakiySpacing.lg) {
                VStack(spacing: ZakiySpacing.sm) {
                    InitialsAvatar(name: profile.username, diameter: 72)
                    Text(profile.username).font(.zakiyTitle)
                    if let school = profile.schoolName, !school.isEmpty {
                        Text(school).font(.zakiySubheadline).foregroundStyle(Color.zakiyTextSecondary)
                    }
                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio).font(.zakiyBody).multilineTextAlignment(.center)
                    }
                    if profile.isPrivate && !profile.isOwner {
                        ZakiyChip(text: "حساب خاص")
                    }
                }

                if !profile.isOwner {
                    friendActionButton(profile)
                }

                if let performance = profile.performance {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "الأداء")
                            HStack(spacing: ZakiySpacing.md) {
                                StatTile(title: "محاولات", value: "\(performance.attemptsCount)", systemImage: "checklist", tint: Color.zakiyNavy)
                                StatTile(title: "متوسط الدرجات", value: "\(performance.avgScore)%", systemImage: "chart.bar.fill", tint: Color.zakiyTeal)
                                StatTile(title: "ستريك", value: "\(performance.currentStreak)", systemImage: "flame.fill", tint: .orange)
                            }
                        }
                    }
                }

                if let library = profile.library {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "المكتبة", subtitle: "\(library.count) ملف")
                            ForEach(library.titles, id: \.self) { title in
                                Text(title).font(.zakiySubheadline)
                            }
                        }
                    }
                }

                if let friends = profile.friends {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "الأصدقاء", subtitle: "\(friends.count)")
                            ForEach(friends.list) { friend in
                                Text(friend.username).font(.zakiySubheadline)
                            }
                        }
                    }
                }

                if let archive = profile.archive, !archive.isEmpty {
                    ZakiyCard {
                        VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                            SectionHeader(title: "آخر الجلسات")
                            ForEach(archive) { session in
                                Text(session.roomType == "classroom" ? "درس مباشر · \(session.roomCode ?? "")" : "غرفة جماعية · \(session.roomCode ?? "")")
                                    .font(.zakiySubheadline)
                            }
                        }
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
    }

    @ViewBuilder
    private func friendActionButton(_ profile: ProfileDetail) -> some View {
        switch profile.friendStatus {
        case .friends:
            ZakiyChip(text: "أصدقاء ✓", tint: Color.zakiyTeal.opacity(0.2), foreground: Color.zakiyTeal)
        case .pendingSent:
            ZakiyChip(text: "طلب مُرسل")
        case .pendingReceived:
            ZakiyChip(text: "عنده طلب منك بانتظار الرد")
        case .none, .selfProfile:
            Button {
                Task { await sendRequest() }
            } label: {
                if isSendingRequest { ProgressView() } else { Label("إضافة صديق", systemImage: "person.badge.plus") }
            }
            .buttonStyle(.zakiyPrimary)
            .fixedSize()
        }
    }

    private func load() async {
        isLoading = true
        do {
            profile = try await APIClient.shared.profile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func sendRequest() async {
        isSendingRequest = true
        defer { isSendingRequest = false }
        do {
            try await APIClient.shared.sendFriendRequest(toUserId: userId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
