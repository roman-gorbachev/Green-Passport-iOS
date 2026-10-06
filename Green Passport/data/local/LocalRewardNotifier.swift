import Foundation
import UserNotifications

final class LocalRewardNotifier: RewardNotifier {
    private static let identifierPrefix = "reward_"

    private let settingsRepository: SettingsRepository
    private let notificationLogRepository: NotificationLogRepository
    private let center: UNUserNotificationCenter

    init(
        settingsRepository: SettingsRepository,
        notificationLogRepository: NotificationLogRepository,
        center: UNUserNotificationCenter = .current()
    ) {
        self.settingsRepository = settingsRepository
        self.notificationLogRepository = notificationLogRepository
        self.center = center
    }

    func notifyReward(reason: PointsEarnReason, points: Int, xp: Int) async {
        let title = String(localized: Self.title(for: reason))
        let body = String(localized: .rewardNotificationBodyFormat(points, xp))
        notificationLogRepository.log(title: title, body: body, sentAt: Date())
        guard settingsRepository.isNotificationCategoryEnabled(.tasks) else {
            return
        }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: Self.identifierPrefix + String(reason.rawValue), content: content, trigger: nil)
        try? await center.add(request)
    }

    private static func title(for reason: PointsEarnReason) -> LocalizedStringResource {
        switch reason {
        case .taskCompleted:
            return .rewardReasonTaskCompleted
        case .gamePlayed:
            return .rewardReasonGamePlayed
        case .articleRead:
            return .rewardReasonArticleRead
        case .eventAttended:
            return .rewardReasonEventAttended
        case .feedbackSubmitted:
            return .rewardReasonFeedbackSubmitted
        case .streakBonus:
            return .rewardReasonStreakBonus
        case .surveyAnswered:
            return .rewardReasonSurveyAnswered
        }
    }
}
