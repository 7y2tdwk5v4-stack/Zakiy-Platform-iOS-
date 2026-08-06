import SwiftUI

/// Landing screen shown before sign-in — navy background with the wordmark,
/// matching the brand identity from the reference screenshots while using
/// native full-bleed layout instead of the web's boxed hero section.
struct WelcomeView: View {
    @Binding var continuedAsGuest: Bool
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zakiyNavy.ignoresSafeArea()

                VStack(spacing: ZakiySpacing.xxl) {
                    Spacer()

                    VStack(spacing: ZakiySpacing.md) {
                        ZakiyLogo(size: .system(size: 48, weight: .heavy, design: .rounded), tint: .white)
                        Text("حوّل أي ملف دراسي إلى ملخص واختبار جاهز")
                            .font(.zakiyHeadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ZakiySpacing.xl)
                    }

                    Spacer()

                    VStack(spacing: ZakiySpacing.md) {
                        Button("إنشاء حساب") { showSignUp = true }
                            .buttonStyle(.zakiyAccent)

                        Button("تسجيل الدخول") { showSignIn = true }
                            .buttonStyle(.plain)
                            .font(.zakiyButton)
                            .foregroundStyle(.white)
                            .padding(.vertical, ZakiySpacing.md)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous)
                                    .strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                            )

                        Button {
                            continuedAsGuest = true
                        } label: {
                            Text("المتابعة كضيف")
                                .font(.zakiySubheadline)
                                .foregroundStyle(.white.opacity(0.75))
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
