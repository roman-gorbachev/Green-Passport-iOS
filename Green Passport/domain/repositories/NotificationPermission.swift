protocol NotificationPermission {
    func requestIfNeeded() async -> NotificationAuthorization
    func isAuthorized() async -> Bool
}
