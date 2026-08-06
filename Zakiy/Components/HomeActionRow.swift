import SwiftUI

/// A row used on the home screen and rooms hub's action lists — mustard icon
/// badge, right-aligned title/subtitle, and a leading-edge (visually left,
/// since Arabic is RTL) disclosure chevron, matching the shipped app's rows.
struct HomeActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: ZakiySpacing.md) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.zakiyTextSecondary)

            VStack(alignment: .trailing, spacing: 3) {
                Text(title)
                    .font(.zakiyHeadline)
                    .foregroundStyle(Color.zakiyTextPrimary)
                Text(subtitle)
                    .font(.zakiyCaption)
                    .foregroundStyle(Color.zakiyTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.zakiyMustard)
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)
        }
        .padding(ZakiySpacing.md)
        .background(Color.zakiySurface)
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.lg, style: .continuous))
    }
}
