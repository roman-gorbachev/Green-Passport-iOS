final class IsNotificationCategoryEnabledUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute(_ category: NotificationCategory) -> Bool {
        return settingsRepository.isNotificationCategoryEnabled(category)
    }
}
