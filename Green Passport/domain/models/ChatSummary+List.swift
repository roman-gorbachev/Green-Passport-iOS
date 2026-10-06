import Foundation

extension ChatSummary {
    static func list(groups: [CommunityGroup], forumLastMessageAt: Date?, settings: [ChatId: ChatSettings]) -> [ChatSummary] {
        let forum = ChatSummary(
            chatId: .forum,
            groupName: nil,
            lastMessageAt: forumLastMessageAt,
            settings: settings[.forum] ?? .defaults(for: .forum)
        )
        let groupChats = groups.map { group in
            let chatId = ChatId.group(id: group.id)
            return ChatSummary(
                chatId: chatId,
                groupName: group.name,
                lastMessageAt: group.lastMessageAt,
                settings: settings[chatId] ?? .defaults(for: chatId)
            )
        }
        return ([forum] + groupChats).sorted { lhs, rhs in
            if lhs.settings.isPinned != rhs.settings.isPinned {
                return lhs.settings.isPinned
            }
            return (lhs.lastMessageAt ?? .distantPast) > (rhs.lastMessageAt ?? .distantPast)
        }
    }
}
