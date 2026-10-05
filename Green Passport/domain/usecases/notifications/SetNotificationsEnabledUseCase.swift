final class SetNotificationsEnabledUseCase {
    private let settingsRepository: SettingsRepository
    private let notificationPermission: NotificationPermission
    private let reminderScheduler: ReminderScheduler

    init(settingsRepository: SettingsRepository, notificationPermission: NotificationPermission, reminderScheduler: ReminderScheduler) {
        self.settingsRepository = settingsRepository
        self.notificationPermission = notificationPermission
        self.reminderScheduler = reminderScheduler
    }

    func execute(isEnabled: Bool) async -> NotificationAuthorization {
        guard isEnabled else {
            settingsRepository.setNotificationsEnabled(false)
            reminderScheduler.cancelAllReminders()
            return await notificationPermission.isAuthorized() ? .authorized : .denied
        }
        let authorization = await notificationPermission.requestIfNeeded()
        settingsRepository.setNotificationsEnabled(authorization == .authorized)
        return authorization
    }
}
