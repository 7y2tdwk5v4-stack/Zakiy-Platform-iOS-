import SwiftUI

struct SignUpView: View {
    @Binding var continuedAsGuest: Bool
    @Environment(AuthSession.self) private var authSession
    @Environment(\.dismiss) private var dismiss

    private static let stages = ["ابتدائي", "متوسط", "ثانوي", "جامعي"]

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var stage = stages[2]
    @State private var level = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !username.isEmpty && !email.isEmpty && password.count >= 6 && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("إنشاء حساب")
                        .font(.zakiyHeroTitle)
                    Text("لتتبع أدائك وحفظ مكتبتك")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                }
                .padding(.top, ZakiySpacing.lg)

                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                    ZakiyTextField(title: "الاسم", text: $username)
                    ZakiyTextField(title: "البريد الإلكتروني", text: $email, keyboard: .emailAddress)
                    ZakiyTextField(title: "كلمة المرور (6 أحرف على الأقل)", text: $password, isSecure: true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("المرحلة الدراسية")
                            .font(.zakiyCaption)
                            .foregroundStyle(Color.zakiyTextSecondary)
                        Picker("المرحلة الدراسية", selection: $stage) {
                            ForEach(Self.stages, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    ZakiyTextField(title: "المستوى/الصف (اختياري)", text: $level)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("إنشاء الحساب")
                    }
                }
                .buttonStyle(.zakiyPrimary)
                .disabled(!canSubmit)
            }
            .padding(ZakiySpacing.xl)
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = try await SupabaseAuthClient.shared.signUp(
                email: email, password: password, username: username,
                stage: stage, level: level.isEmpty ? nil : level
            )
            authSession.adopt(session)
            try? await APIClient.shared.syncProfile(username: username)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(continuedAsGuest: .constant(false))
            .environment(AuthSession.shared)
    }
}
