import SwiftUI

struct FriendsView: View {
    @Environment(AuthSession.self) private var authSession

    private enum Tab: String, CaseIterable { case friends = "أصدقائي", requests = "الطلبات", search = "بحث" }

    @State private var tab: Tab = .friends
    @State private var friends: [Friend] = []
    @State private var requests: FriendRequestsResponse?
    @State private var searchQuery = ""
    @State private var searchResults: [FriendSearchResult] = []
    @State private var invites: [SessionInvite] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !authSession.isSignedIn {
                SignedOutPlaceholder(feature: "قائمة أصدقائك")
            } else {
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(ZakiySpacing.lg)

                    if !invites.isEmpty {
                        inviteBanner
                    }

                    if let errorMessage {
                        ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                            .padding(.horizontal, ZakiySpacing.lg)
                    }

                    if isLoading {
                        LoadingView()
                    } else {
                        switch tab {
                        case .friends: friendsList
                        case .requests: requestsList
                        case .search: searchView
                        }
                    }
                }
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("الأصدقاء")
        .task { await loadAll() }
    }

    private var inviteBanner: some View {
        VStack(alignment: .leading, spacing: ZakiySpacing.sm) {
            ForEach(invites) { invite in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(invite.fromUsername ?? "صديقك") دعاك لغرفة \(invite.roomCode)")
                            .font(.zakiySubheadline)
                        Text(invite.roomType == "classroom" ? "درس مباشر" : "غرفة جماعية")
                            .font(.zakiyCaption)
                            .foregroundStyle(Color.zakiyTextSecondary)
                    }
                    Spacer()
                    Button("تجاهل") { Task { await dismissInvite(invite) } }
                        .font(.zakiyCaption)
                }
                .padding(ZakiySpacing.md)
                .background(Color.zakiyMustard.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
            }
        }
        .padding(.horizontal, ZakiySpacing.lg)
        .padding(.bottom, ZakiySpacing.sm)
    }

    private var friendsList: some View {
        Group {
            if friends.isEmpty {
                EmptyStateView(systemImage: "person.2", title: "ما فيه أصدقاء بعد", message: "دور عليهم من تبويب بحث")
            } else {
                List(friends) { friend in
                    NavigationLink(value: friend) {
                        HStack {
                            InitialsAvatar(name: friend.username, diameter: 36)
                            Text(friend.username).font(.zakiyBody)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { Task { await remove(friend) } } label: {
                            Label("حذف", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: Friend.self) { friend in
                    ProfileView(userId: friend.userId)
                }
            }
        }
    }

    private var requestsList: some View {
        List {
            if let requests, !requests.incoming.isEmpty {
                Section("واردة") {
                    ForEach(requests.incoming) { request in
                        HStack {
                            Text(request.username)
                            Spacer()
                            Button("قبول") { Task { await accept(request) } }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.zakiyTeal)
                            Button("رفض") { Task { await reject(request) } }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            if let requests, !requests.outgoing.isEmpty {
                Section("صادرة") {
                    ForEach(requests.outgoing) { request in
                        HStack {
                            Text(request.username)
                            Spacer()
                            Text("بانتظار الرد").font(.zakiyCaption).foregroundStyle(Color.zakiyTextSecondary)
                        }
                    }
                }
            }
            if let requests, requests.incoming.isEmpty, requests.outgoing.isEmpty {
                Text("ما فيه طلبات صداقة حاليًا").foregroundStyle(Color.zakiyTextSecondary)
            }
        }
        .listStyle(.plain)
    }

    private var searchView: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.zakiyTextSecondary)
                TextField("اسم المستخدم", text: $searchQuery)
                    .onSubmit { Task { await search() } }
            }
            .padding(ZakiySpacing.md)
            .background(Color.zakiyMutedSurface)
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
            .padding(.horizontal, ZakiySpacing.lg)

            List(searchResults) { result in
                HStack {
                    NavigationLink(value: result) {
                        HStack {
                            InitialsAvatar(name: result.username, diameter: 36)
                            Text(result.username)
                        }
                    }
                    Spacer()
                    Button {
                        Task { await sendRequest(result) }
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: FriendSearchResult.self) { result in
                ProfileView(userId: result.userId)
            }
        }
    }

    private func loadAll() async {
        guard authSession.isSignedIn else { return }
        isLoading = true
        async let friendsResult = try? APIClient.shared.friends()
        async let requestsResult = try? APIClient.shared.friendRequests()
        async let invitesResult = try? APIClient.shared.sessionInvites()
        friends = await friendsResult ?? []
        requests = await requestsResult
        invites = await invitesResult ?? []
        isLoading = false
    }

    private func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { searchResults = []; return }
        do {
            searchResults = try await APIClient.shared.searchFriends(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendRequest(_ result: FriendSearchResult) async {
        do { try await APIClient.shared.sendFriendRequest(toUserId: result.userId) }
        catch { errorMessage = error.localizedDescription }
    }

    private func accept(_ request: FriendRequestItem) async {
        do {
            try await APIClient.shared.acceptFriendRequest(id: request.id)
            await loadAll()
        } catch { errorMessage = error.localizedDescription }
    }

    private func reject(_ request: FriendRequestItem) async {
        do {
            try await APIClient.shared.rejectFriendRequest(id: request.id)
            await loadAll()
        } catch { errorMessage = error.localizedDescription }
    }

    private func remove(_ friend: Friend) async {
        do {
            try await APIClient.shared.removeFriend(userId: friend.userId)
            friends.removeAll { $0.id == friend.id }
        } catch { errorMessage = error.localizedDescription }
    }

    private func dismissInvite(_ invite: SessionInvite) async {
        do {
            try await APIClient.shared.dismissInvite(id: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch { errorMessage = error.localizedDescription }
    }
}

#Preview {
    NavigationStack { FriendsView() }
        .environment(AuthSession.shared)
}
