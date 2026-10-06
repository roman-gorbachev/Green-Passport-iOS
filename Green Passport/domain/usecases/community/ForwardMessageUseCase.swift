final class ForwardMessageUseCase {
    private let postToForum: PostToForumUseCase
    private let sendGroupMessage: SendGroupMessageUseCase

    init(postToForum: PostToForumUseCase, sendGroupMessage: SendGroupMessageUseCase) {
        self.postToForum = postToForum
        self.sendGroupMessage = sendGroupMessage
    }

    func execute(text: String, origin: ForwardOrigin, to chat: ChatId, senderId: String) async throws {
        switch chat {
        case .forum:
            try await postToForum.execute(authorId: senderId, text: text, forwardedFrom: origin)
        case .group(let id):
            try await sendGroupMessage.execute(groupId: id, senderId: senderId, text: text, forwardedFrom: origin)
        }
    }
}
