import SwiftUI

/// The "ذكيّ" wordmark exactly as it appears in the shipped app: a bold
/// wordmark bracketed by two thin rule lines, with a mustard highlight bar
/// sitting just beneath it.
struct ZakiyLogo: View {
    var textSize: CGFloat = 46
    var frameWidth: CGFloat = 175

    var body: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(Color.zakiyTextSecondary.opacity(0.35))
                .frame(width: frameWidth, height: 1)

            Text("ذكيّ")
                .font(.system(size: textSize, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.zakiyTextPrimary)

            VStack(spacing: 6) {
                Rectangle()
                    .fill(Color.zakiyTextSecondary.opacity(0.35))
                    .frame(width: frameWidth, height: 1)
                Rectangle()
                    .fill(Color.zakiyMustard)
                    .frame(width: frameWidth * 0.56, height: textSize * 0.18)
            }
        }
    }
}

#Preview {
    ZakiyLogo()
        .padding()
        .background(Color.zakiyBackground)
}
