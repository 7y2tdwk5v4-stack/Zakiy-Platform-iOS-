import SwiftUI

/// Signed-in app shell — matches the shipped app's exact five-tab bar
/// (الرئيسية / الغرف / المكتبة / أدائي / الإعدادات). الأصدقاء and مساعد ذكيّ
/// don't have their own tab in the real app; they're reachable from
/// الإعدادات until screenshots of their real placement are available.
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }

            NavigationStack { RoomsHubView() }
                .tabItem { Label("الغرف", systemImage: "person.3.fill") }

            NavigationStack { LibraryView() }
                .tabItem { Label("المكتبة", systemImage: "books.vertical.fill") }

            NavigationStack { PerformanceView() }
                .tabItem { Label("أدائي", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack { SettingsView() }
                .tabItem { Label("الإعدادات", systemImage: "gearshape.fill") }
        }
        .tint(Color.zakiyMustard)
    }
}
