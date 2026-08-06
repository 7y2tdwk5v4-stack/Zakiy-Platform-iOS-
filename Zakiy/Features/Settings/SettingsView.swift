import SwiftUI

struct SettingsView: View {
    @Environment(AuthSession.self) private var authSession
    @AppStorage("zakiy.colorScheme") private var colorScheme: String = "system"
    @AppStorage("zakiy.continuedAsGuest") private var continuedAsGuest = false
    @State private var showSignOutConfirm = false

    var body: some View {
        Form {
            Section("الحساب") {
                if authSession.isSignedIn {
                    HStack {
                        InitialsAvatar(name: authSession.displayName, diameter: 44)
                        VStack(alignment: .leading) {
                            Text(authSession.displayName).font(.zakiyBody.weight(.semibold))
                            Text("حساب مسجّل").font(.zakiyCaption).foregroundStyle(Color.zakiyTextSecondary)
                        }
                    }
                } else {
                    Text("أنت تستخدم ذكيّ كضيف — سجّل حساب عشان تحفظ نتائجك ومكتبتك")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                }
            }

            Section {
                NavigationLink {
                    FriendsView()
                } label: {
                    Label("الأصدقاء", systemImage: "person.2.fill")
                }
                NavigationLink {
                    SiteHelpView()
                } label: {
                    Label("مساعد ذكيّ", systemImage: "sparkles")
                }
            }

            Section("المظهر") {
                Picker("المظهر", selection: $colorScheme) {
                    Text("حسب النظام").tag("system")
                    Text("فاتح").tag("light")
                    Text("داكن").tag("dark")
                }
            }

            Section {
                if authSession.isSignedIn {
                    Button("تسجيل الخروج", role: .destructive) { showSignOutConfirm = true }
                } else {
                    Button("تسجيل الدخول / إنشاء حساب") {
                        continuedAsGuest = false
                    }
                }
            }
        }
        .navigationTitle("الإعدادات")
        .confirmationDialog("تسجيل الخروج؟", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("تسجيل الخروج", role: .destructive) {
                authSession.signOut()
                continuedAsGuest = false
            }
            Button("إلغاء", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AuthSession.shared)
}
