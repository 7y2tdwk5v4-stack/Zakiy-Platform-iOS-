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
            VStack(spacing: ZakiySpacing.xxl) {
                ZakiyLogo(textSize: 20, frameWidth: 76)
                    .padding(.top, ZakiySpacing.sm)

                VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("أهلًا، \(authSession.displayName)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.zakiyTextPrimary)
                        Text("جاهز تذاكر اليوم؟")
                            .font(.zakiySubheadline)
                            .foregroundStyle(Color.zakiyTextSecondary)
                    }

                    VStack(spacing: ZakiySpacing.md) {
                        NavigationLink(value: HomeRoute.solo) {
                            HomeActionRow(title: "ارفع ملف PDF", subtitle: "ابدأ مذاكرة فردية من ملف جديد", systemImage: "doc.badge.plus")
                        }
                        NavigationLink(value: HomeRoute.group) {
                            HomeActionRow(title: "غرفة جماعية", subtitle: "ادرس مع زملائك بغرفة مباشرة", systemImage: "person.3.fill")
                        }
                        NavigationLink(value: HomeRoute.liveClass) {
                            HomeActionRow(title: "درس مباشر", subtitle: "سبورة وصوت جماعي حي مع طلابك", systemImage: "person.text.rectangle.fill")
                        }
                    }
                    .buttonStyle(.plain)
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
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack { HomeView() }
        .environment(AuthSession.shared)
}
