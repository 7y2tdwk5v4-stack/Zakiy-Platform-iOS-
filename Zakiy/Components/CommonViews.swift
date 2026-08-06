import SwiftUI

/// Centered spinner + message, used while a network call is in flight.
struct LoadingView: View {
    var message: String = "جارٍ التحميل..."

    var body: some View {
        VStack(spacing: ZakiySpacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.zakiySubheadline)
                .foregroundStyle(Color.zakiyTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty-state placeholder (no library books, no friends, no sessions yet…).
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: ZakiySpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Color.zakiyTextSecondary)
            Text(title)
                .font(.zakiyHeadline)
                .foregroundStyle(Color.zakiyTextPrimary)
            if let message {
                Text(message)
                    .font(.zakiySubheadline)
                    .foregroundStyle(Color.zakiyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ZakiySpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

/// Inline error banner shown at the top of a screen when a request fails.
struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: ZakiySpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.zakiySubheadline)
                .foregroundStyle(Color.zakiyTextPrimary)
            Spacer(minLength: 0)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.zakiyTextSecondary)
                }
            }
        }
        .padding(ZakiySpacing.md)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ZakiyRadius.sm, style: .continuous))
    }
}

/// Section header used above list groups ("نقاط الضعف", "الملفات المحفوظة"…).
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.zakiyHeadline)
                .foregroundStyle(Color.zakiyTextPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.zakiyCaption)
                    .foregroundStyle(Color.zakiyTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small rounded label used for topics, stats, streaks, room codes.
struct ZakiyChip: View {
    let text: String
    var tint: Color = .zakiyMutedSurface
    var foreground: Color = .zakiyTextPrimary

    var body: some View {
        Text(text)
            .font(.zakiyCaption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, ZakiySpacing.md)
            .padding(.vertical, 6)
            .background(tint)
            .clipShape(Capsule())
    }
}

/// Circular initials avatar used for friends/profile lists.
struct InitialsAvatar: View {
    let name: String
    var diameter: CGFloat = 40

    private var initial: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(Color.zakiyNavy)
            .frame(width: diameter, height: diameter)
            .overlay(
                Text(initial.isEmpty ? "؟" : initial)
                    .font(.system(size: diameter * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
    }
}

/// Five-star session rating, mirrors `compute_session_rating` on the backend.
struct StarRatingView: View {
    let stars: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= stars ? "star.fill" : "star")
                    .foregroundStyle(Color.zakiyMustard)
            }
        }
    }
}
