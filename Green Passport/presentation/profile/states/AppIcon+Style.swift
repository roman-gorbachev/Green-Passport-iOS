import Foundation

extension AppIcon {
    var title: LocalizedStringResource {
        switch self {
        case .standard:
            return .appIconStandard
        case .dark:
            return .appIconDark
        }
    }

    var systemImage: String {
        switch self {
        case .standard:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}
