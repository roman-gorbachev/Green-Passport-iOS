final class UpdateChatSettingsUseCase {
    private let chatSettingsRepository: ChatSettingsRepository

    init(chatSettingsRepository: ChatSettingsRepository) {
        self.chatSettingsRepository = chatSettingsRepository
    }

    func execute(_ settings: ChatSettings, userId: String) async throws {
        try await chatSettingsRepository.save(settings, userId: userId)
    }
}
