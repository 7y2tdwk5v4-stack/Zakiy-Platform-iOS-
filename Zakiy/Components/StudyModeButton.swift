import SwiftUI

/// Visual content shared by the three "what do you want to do today" entry
/// points on the home screen (solo study / group room / live class) — an SF
/// Symbol over a navy pill, the native equivalent of the web's emoji buttons.
struct StudyModeButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: ZakiySpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
            Text(title)
                .font(.zakiyButton)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, ZakiySpacing.lg)
        .background(Color.zakiyNavy)
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.md, style: .continuous))
    }
}

/// Tap-to-run variant of `StudyModeButtonLabel` for contexts that need a
/// plain action instead of stack navigation.
struct StudyModeButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            StudyModeButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        StudyModeButton(title: "مذاكرة فردية", systemImage: "person.fill") {}
        StudyModeButton(title: "غرفة جماعية", systemImage: "person.2.fill") {}
        StudyModeButton(title: "درس مباشر", systemImage: "pencil.and.outline") {}
    }
    .padding()
    .background(Color.zakiyBackground)
}
