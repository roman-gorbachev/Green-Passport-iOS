import Foundation

extension NotificationCategory {
    var title: LocalizedStringResource {
        switch self {
        case .events:
            return .notificationsEvents
        case .tasks:
            return .notificationsTasks
        case .messages:
            return .notificationsMessages
        }
    }

    var systemImage: String {
        switch self {
        case .events:
            return "calendar"
        case .tasks:
            return "checklist"
        case .messages:
            return "bubble.left.and.bubble.right.fill"
        }
    }
}
