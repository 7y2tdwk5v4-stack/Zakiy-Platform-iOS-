import SwiftUI

/// Text styles built on Dynamic Type so the app follows the platform's own
/// scaling rules instead of the fixed pixel sizes used on the web.
extension Font {
    static let zakiyLogo = Font.system(.title2, design: .rounded).weight(.heavy)
    static let zakiyHeroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let zakiyTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let zakiyHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let zakiyBody = Font.system(.body)
    static let zakiySubheadline = Font.system(.subheadline)
    static let zakiyCaption = Font.system(.caption)
    static let zakiyButton = Font.system(.body, design: .rounded).weight(.semibold)
}

enum ZakiySpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum ZakiyRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let pill: CGFloat = 999
}
