protocol ChatSettingsRepository {
    func observeSettings(userId: String) -> AsyncThrowingStream<[ChatId: ChatSettings], Error>
    func save(_ settings: ChatSettings, userId: String) async throws
}
