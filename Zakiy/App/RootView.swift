import SwiftUI

/// Signed-in app shell. Mirrors the web sidebar's sections (الرئيسية / أدائي /
/// الأرشيف / الأصدقاء / مكتبتي / مساعد ذكيّ / الإعدادات) as a native iOS tab
/// bar — SF Symbols instead of emoji, and the overflow "More" tab iOS shows
/// automatically past five items instead of a scrolling sidebar list.
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }

            NavigationStack { PerformanceView() }
                .tabItem { Label("أدائي", systemImage: "chart.bar.fill") }

            NavigationStack { ArchiveView() }
                .tabItem { Label("الأرشيف", systemImage: "archivebox.fill") }

            NavigationStack { FriendsView() }
                .tabItem { Label("الأصدقاء", systemImage: "person.2.fill") }

            NavigationStack { LibraryView() }
                .tabItem { Label("مكتبتي", systemImage: "books.vertical.fill") }

            NavigationStack { SiteHelpView() }
                .tabItem { Label("مساعد ذكيّ", systemImage: "sparkles") }

            NavigationStack { SettingsView() }
                .tabItem { Label("الإعدادات", systemImage: "gearshape.fill") }
        }
    }
}
