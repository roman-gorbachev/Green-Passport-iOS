protocol MessageNotificationsRepository {
    func observeIsEnabled(userId: String) -> AsyncThrowingStream<Bool, Error>
    func setEnabled(_ isEnabled: Bool, userId: String) async throws
}
