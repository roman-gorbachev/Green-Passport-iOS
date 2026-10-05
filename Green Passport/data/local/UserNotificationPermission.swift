import UserNotifications

final class UserNotificationPermission: NotificationPermission {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestIfNeeded() async -> NotificationAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .notDetermined:
            let isGranted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            return isGranted == true ? .authorized : .denied
        default:
            return .denied
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
}
