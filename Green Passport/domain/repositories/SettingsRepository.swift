protocol SettingsRepository {
    var isOnboardingSeen: Bool { get }
    var theme: AppTheme { get }
    func markOnboardingSeen()
    func isNotificationCategoryEnabled(_ category: NotificationCategory) -> Bool
    func setNotificationCategory(_ category: NotificationCategory, isEnabled: Bool)
    func setTheme(_ theme: AppTheme)
}
