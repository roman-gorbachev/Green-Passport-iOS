import Foundation

protocol ReminderScheduler {
    func scheduleEventReminder(eventId: String, title: String, at date: Date) async
    func cancelEventReminder(eventId: String)
    func scheduleCouponReminder(couponId: String, title: String, expiresAt: Date) async
    func cancelCouponReminder(couponId: String)
    func scheduleStreakReminder(streakDays: Int, at date: Date) async
    func cancelStreakReminder()
    func cancelReminders(for category: NotificationCategory) async
}
