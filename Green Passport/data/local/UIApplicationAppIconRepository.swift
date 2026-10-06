import UIKit

final class UIApplicationAppIconRepository: AppIconRepository {
    private static let darkIconName = "AppIconDark"

    var isSupported: Bool {
        return UIApplication.shared.supportsAlternateIcons
    }

    var current: AppIcon {
        return UIApplication.shared.alternateIconName == Self.darkIconName ? .dark : .standard
    }

    func set(_ icon: AppIcon) async throws {
        let iconName = icon == .dark ? Self.darkIconName : nil
        guard isSupported, UIApplication.shared.alternateIconName != iconName else {
            return
        }
        try await UIApplication.shared.setAlternateIconName(iconName)
    }
}
