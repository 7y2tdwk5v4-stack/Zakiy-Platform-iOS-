import SwiftUI

struct SignInView: View {
    @Binding var continuedAsGuest: Bool
    @Environment(AuthSession.self) private var authSession
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty && !isLoading }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZakiySpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("تسجيل الدخول")
                        .font(.zakiyHeroTitle)
                    Text("رجّع نتائجك ومكتبتك من آخر مرة")
                        .font(.zakiySubheadline)
                        .foregroundStyle(Color.zakiyTextSecondary)
                }
                .padding(.top, ZakiySpacing.lg)

                if let errorMessage {
                    ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                }

                VStack(alignment: .leading, spacing: ZakiySpacing.md) {
                    ZakiyTextField(title: "البريد الإلكتروني", text: $email, keyboard: .emailAddress)
                    ZakiyTextField(title: "كلمة المرور", text: $password, isSecure: true)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("دخول")
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
            let session = try await SupabaseAuthClient.shared.signIn(email: email, password: password)
            authSession.adopt(session)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Rounded text field matching the card-based input style used across the
/// app's forms.
struct ZakiyTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.zakiyCaption)
                .foregroundStyle(Color.zakiyTextSecondary)
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.zakiyBody)
            .padding(ZakiySpacing.md)
            .background(Color.zakiyMutedSurface)
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        SignInView(continuedAsGuest: .constant(false))
            .environment(AuthSession.shared)
    }
}
