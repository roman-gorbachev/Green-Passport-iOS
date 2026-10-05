import Foundation
import UserNotifications

final class LocalNotificationReminderScheduler: ReminderScheduler {
    private static let identifierPrefix = "event_reminder_"
    private static let couponIdentifierPrefix = "coupon_expiring_"
    private static let streakIdentifier = "streak_reminder"
    private static let couponReminderLeadTime: TimeInterval = 24 * 60 * 60
    private static let minimumTriggerDelay: TimeInterval = 1

    private let settingsRepository: SettingsRepository
    private let notificationLogRepository: NotificationLogRepository
    private let notificationPermission: NotificationPermission
    private let center: UNUserNotificationCenter

    init(
        settingsRepository: SettingsRepository,
        notificationLogRepository: NotificationLogRepository,
        notificationPermission: NotificationPermission,
        center: UNUserNotificationCenter = .current()
    ) {
        self.settingsRepository = settingsRepository
        self.notificationLogRepository = notificationLogRepository
        self.notificationPermission = notificationPermission
        self.center = center
    }

    func scheduleEventReminder(eventId: String, title: String, at date: Date) async {
        await schedule(
            identifier: Self.identifierPrefix + eventId,
            title: String(localized: .eventReminderTitle),
            body: title,
            at: date
        )
    }

    func scheduleCouponReminder(couponId: String, title: String, expiresAt: Date) async {
        let fireDate = expiresAt.addingTimeInterval(-Self.couponReminderLeadTime)
        guard fireDate > Date() else {
            return
        }
        await schedule(
            identifier: Self.couponIdentifierPrefix + couponId,
            title: String(localized: .couponExpiresSoon),
            body: String(localized: .couponValidUntilTomorrowMsg(title)),
            at: fireDate
        )
    }

    func cancelCouponReminder(couponId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.couponIdentifierPrefix + couponId])
    }

    func scheduleStreakReminder(streakDays: Int, at date: Date) async {
        await deliver(
            identifier: Self.streakIdentifier,
            title: String(localized: .streakReminderTitle),
            body: String(localized: .streakReminderBody(streakDays)),
            at: date
        )
    }

    func cancelStreakReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.streakIdentifier])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    private func schedule(identifier: String, title: String, body: String, at fireDate: Date) async {
        guard await deliver(identifier: identifier, title: title, body: body, at: fireDate) else {
            return
        }
        notificationLogRepository.log(title: title, body: body, sentAt: max(fireDate, Date()))
    }

    @discardableResult
    private func deliver(identifier: String, title: String, body: String, at fireDate: Date) async -> Bool {
        guard settingsRepository.isNotificationsEnabled, await notificationPermission.requestIfNeeded() == .authorized else {
            return false
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let delay = max(fireDate.timeIntervalSinceNow, Self.minimumTriggerDelay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func cancelEventReminder(eventId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifierPrefix + eventId])
    }
}
