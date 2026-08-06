import SwiftUI

/// The "ذكيّ" wordmark: bold rounded type with a short mustard underline
/// accent, the native counterpart of the web logo's bold text + gold dash.
struct ZakiyLogo: View {
    var size: Font = .zakiyLogo
    var tint: Color = .zakiyTextPrimary

    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            Text("ذكيّ")
                .font(size)
                .foregroundStyle(tint)
            Capsule()
                .fill(Color.zakiyMustard)
                .frame(width: 28, height: 4)
        }
    }
}

#Preview {
    ZakiyLogo()
        .padding()
}
