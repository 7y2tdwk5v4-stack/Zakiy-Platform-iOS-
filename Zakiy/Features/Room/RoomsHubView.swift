import SwiftUI

/// "الغرف" tab — entry point for both real-time modes (group study rooms and
/// live classes) plus this student's session archive, consolidated into one
/// tab to match the shipped app's simpler five-tab navigation.
struct RoomsHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("الغرف")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.zakiyTextPrimary)
                    Text("ذاكر جماعيًا أو ابدأ حصة مباشرة")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                }

                VStack(spacing: ZakiySpacing.md) {
                    NavigationLink {
                        RoomEntryView(roomType: "quiz")
                    } label: {
                        HomeActionRow(title: "غرفة جماعية", subtitle: "ادرس مع زملائك بغرفة مباشرة", systemImage: "person.3.fill")
                    }
                    NavigationLink {
                        RoomEntryView(roomType: "classroom")
                    } label: {
                        HomeActionRow(title: "درس مباشر", subtitle: "سبورة وصوت جماعي حي مع طلابك", systemImage: "person.text.rectangle.fill")
                    }
                    NavigationLink {
                        ArchiveView()
                    } label: {
                        HomeActionRow(title: "الأرشيف", subtitle: "جلساتك الجماعية والحصص السابقة", systemImage: "archivebox.fill")
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(ZakiySpacing.lg)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { RoomsHubView() }
        .environment(AuthSession.shared)
}
