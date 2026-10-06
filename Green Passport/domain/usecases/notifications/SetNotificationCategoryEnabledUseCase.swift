final class SetNotificationCategoryEnabledUseCase {
    private let settingsRepository: SettingsRepository
    private let messageNotificationsRepository: MessageNotificationsRepository
    private let notificationPermission: NotificationPermission
    private let reminderScheduler: ReminderScheduler

    init(
        settingsRepository: SettingsRepository,
        messageNotificationsRepository: MessageNotificationsRepository,
        notificationPermission: NotificationPermission,
        reminderScheduler: ReminderScheduler
    ) {
        self.settingsRepository = settingsRepository
        self.messageNotificationsRepository = messageNotificationsRepository
        self.notificationPermission = notificationPermission
        self.reminderScheduler = reminderScheduler
    }

    func execute(_ category: NotificationCategory, isEnabled: Bool, userId: String?) async -> NotificationAuthorization {
        guard isEnabled else {
            await store(category, isEnabled: false, userId: userId)
            await reminderScheduler.cancelReminders(for: category)
            return await notificationPermission.isAuthorized() ? .authorized : .denied
        }
        let authorization = await notificationPermission.requestIfNeeded()
        await store(category, isEnabled: authorization == .authorized, userId: userId)
        return authorization
    }

    private func store(_ category: NotificationCategory, isEnabled: Bool, userId: String?) async {
        settingsRepository.setNotificationCategory(category, isEnabled: isEnabled)
        guard category == .messages, let userId else {
            return
        }
        try? await messageNotificationsRepository.setEnabled(isEnabled, userId: userId)
    }
}
