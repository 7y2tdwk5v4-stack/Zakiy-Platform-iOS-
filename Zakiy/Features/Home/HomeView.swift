import SwiftUI

enum HomeRoute: Hashable {
    case solo
    case group
    case liveClass
}

struct HomeView: View {
    @Environment(AuthSession.self) private var authSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.xl) {
                header

                VStack(alignment: .leading, spacing: ZakiySpacing.sm) {
                    Text("حوّل أي ملف دراسي إلى ملخص واختبار جاهز")
                        .font(.zakiyHeroTitle)
                        .foregroundStyle(Color.zakiyTextPrimary)
                    Text("ارفع ملزمة أو أوراق عمل بصيغة PDF، وخلّ ذكيّ يلخصها ويحول محتواها لاختبار تفاعلي يقيس فهمك.")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                }

                ZakiyCard {
                    VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                        if authSession.isSignedIn {
                            Label("Welcome \(authSession.displayName)", systemImage: "hand.wave.fill")
                                .font(.zakiySubheadline.weight(.semibold))
                                .foregroundStyle(Color.zakiyTeal)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("وش تبي تسوي اليوم؟")
                                .font(.zakiyTitle)
                                .foregroundStyle(Color.zakiyTextPrimary)
                            Text("اختر طريقة المذاكرة عشان نبدأ")
                                .font(.zakiyCaption)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }

                        HStack(spacing: ZakiySpacing.md) {
                            NavigationLink(value: HomeRoute.solo) {
                                StudyModeButtonLabel(title: "مذاكرة فردية", systemImage: "brain.head.profile")
                            }
                            NavigationLink(value: HomeRoute.group) {
                                StudyModeButtonLabel(title: "غرفة جماعية", systemImage: "person.2.fill")
                            }
                            NavigationLink(value: HomeRoute.liveClass) {
                                StudyModeButtonLabel(title: "درس مباشر", systemImage: "pencil.and.outline")
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .solo: SoloUploadView()
            case .group: RoomEntryView(roomType: "quiz")
            case .liveClass: RoomEntryView(roomType: "classroom")
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            ZakiyLogo()
            Spacer()
            NavigationLink {
                if let userId = authSession.userId {
                    ProfileView(userId: userId)
                }
            } label: {
                InitialsAvatar(name: authSession.displayName, diameter: 36)
            }
            .disabled(!authSession.isSignedIn)
        }
    }
}

#Preview {
    NavigationStack { HomeView() }
        .environment(AuthSession.shared)
}
