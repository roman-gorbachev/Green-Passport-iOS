import Foundation

final class UserDefaultsSettingsRepository: SettingsRepository {
    private static let onboardingSeenKey = "onboarding_seen"
    private static let legacyNotificationsEnabledKey = "notifications_enabled"
    static let themeKey = "app_theme"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isOnboardingSeen: Bool {
        return defaults.bool(forKey: Self.onboardingSeenKey)
    }

    func isNotificationCategoryEnabled(_ category: NotificationCategory) -> Bool {
        let legacyValue = defaults.object(forKey: Self.legacyNotificationsEnabledKey) as? Bool ?? true
        return defaults.object(forKey: Self.key(for: category)) as? Bool ?? legacyValue
    }

    var theme: AppTheme {
        return defaults.string(forKey: Self.themeKey).flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Self.themeKey)
    }

    func setNotificationCategory(_ category: NotificationCategory, isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Self.key(for: category))
    }

    private static func key(for category: NotificationCategory) -> String {
        return "notifications_\(category.rawValue)_enabled"
    }

    func markOnboardingSeen() {
        defaults.set(true, forKey: Self.onboardingSeenKey)
    }
}
