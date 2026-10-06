final class DeleteMessageUseCase {
    private let communityRepository: CommunityRepository

    init(communityRepository: CommunityRepository) {
        self.communityRepository = communityRepository
    }

    func execute(chat: ChatId, messageId: String) async throws {
        try await communityRepository.deleteMessage(in: chat, messageId: messageId)
    }
}
