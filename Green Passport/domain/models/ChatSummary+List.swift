import Foundation

extension ChatSummary {
    static func forum(lastMessageAt: Date?, settings: [ChatId: ChatSettings]) -> ChatSummary {
        return ChatSummary(
            chatId: .forum,
            groupName: nil,
            lastMessageAt: lastMessageAt,
            settings: settings[.forum] ?? .defaults(for: .forum)
        )
    }

    static func groups(_ groups: [CommunityGroup], settings: [ChatId: ChatSettings]) -> [ChatSummary] {
        return groups
            .map { group in
                let chatId = ChatId.group(id: group.id)
                return ChatSummary(
                    chatId: chatId,
                    groupName: group.name,
                    lastMessageAt: group.lastMessageAt,
                    settings: settings[chatId] ?? .defaults(for: chatId)
                )
            }
            .sorted { lhs, rhs in
                if lhs.settings.isPinned != rhs.settings.isPinned {
                    return lhs.settings.isPinned
                }
                return (lhs.lastMessageAt ?? .distantPast) > (rhs.lastMessageAt ?? .distantPast)
            }
    }
}
