final class SendGroupMessageUseCase {
    private let communityRepository: CommunityRepository
    private let userProfileRepository: UserProfileRepository
    private let textModerator: TextModerator

    init(
        communityRepository: CommunityRepository,
        userProfileRepository: UserProfileRepository,
        textModerator: TextModerator
    ) {
        self.communityRepository = communityRepository
        self.userProfileRepository = userProfileRepository
        self.textModerator = textModerator
    }

    func execute(groupId: String, senderId: String, text: String, replyTo: MessageQuote? = nil, forwardedFrom: ForwardOrigin? = nil) async throws {
        guard textModerator.isAllowed(text) else {
            throw ContentRejectedError()
        }
        let profile = (try? await userProfileRepository.observeProfile(userId: senderId).firstValue()) ?? nil
        try await communityRepository.sendMessage(
            groupId: groupId,
            senderId: senderId,
            senderName: profile?.displayName,
            senderAvatar: profile?.avatar,
            text: text,
            replyTo: replyTo,
            forwardedFrom: forwardedFrom
        )
    }
}
