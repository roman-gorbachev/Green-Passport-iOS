final class EditMessageUseCase {
    private let communityRepository: CommunityRepository
    private let textModerator: TextModerator

    init(communityRepository: CommunityRepository, textModerator: TextModerator) {
        self.communityRepository = communityRepository
        self.textModerator = textModerator
    }

    func execute(chat: ChatId, messageId: String, text: String) async throws {
        guard textModerator.isAllowed(text) else {
            throw ContentRejectedError()
        }
        try await communityRepository.editMessage(in: chat, messageId: messageId, text: text)
    }
}
