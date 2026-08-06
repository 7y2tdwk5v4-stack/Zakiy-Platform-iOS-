import SwiftUI

/// Landing screen shown before sign-in — matches the shipped app exactly:
/// adaptive background (not a fixed navy hero), framed wordmark, and a
/// gold-filled primary button over a ghost-gold secondary button.
struct WelcomeView: View {
    @Binding var continuedAsGuest: Bool
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zakiyBackground.ignoresSafeArea()

                VStack(spacing: ZakiySpacing.xxl) {
                    Spacer()

                    VStack(spacing: ZakiySpacing.lg) {
                        ZakiyLogo()
                        VStack(spacing: 4) {
                            Text("أهلًا بك في ذكيّ")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.zakiyTextPrimary)
                            Text("منصة مذاكرة جماعية بمساعدة الذكاء الاصطناعي")
                                .font(.zakiySubheadline)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }
                        .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(spacing: ZakiySpacing.md) {
                        Button("إنشاء حساب") { showSignUp = true }
                            .buttonStyle(.zakiyAccent)

                        Button("تسجيل الدخول") { showSignIn = true }
                            .buttonStyle(.zakiyGhostGold)

                        Button {
                            continuedAsGuest = true
                        } label: {
                            Text("استمر بدون حساب")
                                .font(.zakiySubheadline)
                                .foregroundStyle(Color.zakiyTextSecondary)
                        }
                        .padding(.top, ZakiySpacing.sm)
                    }
                    .padding(.horizontal, ZakiySpacing.xl)
                    .padding(.bottom, ZakiySpacing.xxl)
                }
            }
            .navigationDestination(isPresented: $showSignIn) {
                SignInView(continuedAsGuest: $continuedAsGuest)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(continuedAsGuest: $continuedAsGuest)
            }
        }
        .tint(Color.zakiyMustard)
    }
}

#Preview {
    WelcomeView(continuedAsGuest: .constant(false))
}
