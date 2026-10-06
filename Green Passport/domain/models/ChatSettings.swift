import Foundation

nonisolated struct ChatSettings: Hashable, Sendable {
    let chatId: ChatId
    var isPinned: Bool
    var isArchived: Bool
    var isMuted: Bool

    static func defaults(for chatId: ChatId) -> ChatSettings {
        return ChatSettings(chatId: chatId, isPinned: false, isArchived: false, isMuted: chatId == .forum)
    }
}
