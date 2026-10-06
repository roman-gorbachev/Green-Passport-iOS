import Foundation

protocol CommunityRepository {
    func observeForumPosts() -> AsyncThrowingStream<[ForumPost], Error>
    func observeLatestForumPostDate() -> AsyncThrowingStream<Date?, Error>
    func postToForum(authorId: String, authorName: String?, authorAvatar: AvatarStyle?, text: String, replyTo: MessageQuote?, forwardedFrom: ForwardOrigin?) async throws
    func observeGroups() -> AsyncThrowingStream<[CommunityGroup], Error>
    func observeGroup(id: String) -> AsyncThrowingStream<CommunityGroup?, Error>
    func createGroup(name: String, creatorId: String) async throws
    func joinGroup(groupId: String, userId: String) async throws
    func leaveGroup(groupId: String, userId: String) async throws
    func findGroup(inviteCode: String) async throws -> CommunityGroup?
    func observeMessages(groupId: String) -> AsyncThrowingStream<[GroupMessage], Error>
    func sendMessage(groupId: String, senderId: String, senderName: String?, senderAvatar: AvatarStyle?, text: String, replyTo: MessageQuote?, forwardedFrom: ForwardOrigin?) async throws
    func editMessage(in chat: ChatId, messageId: String, text: String) async throws
    func deleteMessage(in chat: ChatId, messageId: String) async throws
    func observeMyGroups(userId: String) -> AsyncThrowingStream<[CommunityGroup], Error>
    func fetchMembers(ids: [String]) async throws -> [GroupMember]
}
