import UIKit

final class UIApplicationAppIconRepository: AppIconRepository {
    var isSupported: Bool {
        return UIApplication.shared.supportsAlternateIcons
    }

    var current: AppIcon {
        let name = UIApplication.shared.alternateIconName
        return AppIcon.allCases.first { return Self.iconName(for: $0) == name } ?? .standard
    }

    func set(_ icon: AppIcon) async throws {
        let iconName = Self.iconName(for: icon)
        guard isSupported, UIApplication.shared.alternateIconName != iconName else {
            return
        }
        try await UIApplication.shared.setAlternateIconName(iconName)
    }

    private static func iconName(for icon: AppIcon) -> String? {
        switch icon {
        case .standard:
            return nil
        case .dark:
            return "AppIconDark"
        case .sunset:
            return "AppIconSunset"
        case .night:
            return "AppIconNight"
        case .ocean:
            return "AppIconOcean"
        case .lime:
            return "AppIconLime"
        }
    }
}
