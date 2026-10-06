final class ObserveChatSettingsUseCase {
    private let chatSettingsRepository: ChatSettingsRepository

    init(chatSettingsRepository: ChatSettingsRepository) {
        self.chatSettingsRepository = chatSettingsRepository
    }

    func execute(userId: String) -> AsyncThrowingStream<[ChatId: ChatSettings], Error> {
        return chatSettingsRepository.observeSettings(userId: userId)
    }
}
