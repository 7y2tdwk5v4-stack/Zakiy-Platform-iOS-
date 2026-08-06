import SwiftUI

/// Filled navy button — the primary call to action, matching the web app's
/// dark navy buttons but with native iOS press/scale feedback.
struct ZakiyPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zakiyButton)
            .foregroundStyle(.white)
            .padding(.vertical, ZakiySpacing.md)
            .padding(.horizontal, ZakiySpacing.xl)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.zakiyNavy.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Mustard-accent button, reserved for the single highest-priority action on
/// a screen (matches the real app's "إنشاء حساب"-style buttons: gold fill,
/// white text).
struct ZakiyAccentButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zakiyButton)
            .foregroundStyle(.white)
            .padding(.vertical, ZakiySpacing.md)
            .padding(.horizontal, ZakiySpacing.xl)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.zakiyMustard.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Neutral pill for lower-emphasis actions (plain label text).
struct ZakiySecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zakiyButton)
            .foregroundStyle(Color.zakiyTextPrimary)
            .padding(.vertical, ZakiySpacing.md)
            .padding(.horizontal, ZakiySpacing.xl)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.zakiyMutedSurface.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Neutral pill with gold text — matches the real app's "تسجيل الدخول"
/// button on the welcome screen: a gray pill carrying the accent color in
/// its label instead of its fill.
struct ZakiyGhostGoldButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.zakiyButton)
            .foregroundStyle(Color.zakiyMustard)
            .padding(.vertical, ZakiySpacing.md)
            .padding(.horizontal, ZakiySpacing.xl)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.zakiyMutedSurface.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ZakiyPrimaryButtonStyle {
    static var zakiyPrimary: ZakiyPrimaryButtonStyle { ZakiyPrimaryButtonStyle() }
}

extension ButtonStyle where Self == ZakiyAccentButtonStyle {
    static var zakiyAccent: ZakiyAccentButtonStyle { ZakiyAccentButtonStyle() }
}

extension ButtonStyle where Self == ZakiySecondaryButtonStyle {
    static var zakiySecondary: ZakiySecondaryButtonStyle { ZakiySecondaryButtonStyle() }
}

extension ButtonStyle where Self == ZakiyGhostGoldButtonStyle {
    static var zakiyGhostGold: ZakiyGhostGoldButtonStyle { ZakiyGhostGoldButtonStyle() }
}
