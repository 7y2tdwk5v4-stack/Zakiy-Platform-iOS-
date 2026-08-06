import SwiftUI

/// Rounded elevated container — the iOS equivalent of the web app's cards,
/// using a soft system shadow instead of the web's flat drop shadow.
struct ZakiyCard<Content: View>: View {
    var padding: CGFloat = ZakiySpacing.lg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.zakiySurface)
            .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ZakiyRadius.lg, style: .continuous)
                    .strokeBorder(Color.zakiyBorder, lineWidth: 0.75)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
