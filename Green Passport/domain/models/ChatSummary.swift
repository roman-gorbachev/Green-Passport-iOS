import Foundation

nonisolated struct ChatSummary: Identifiable, Hashable, Sendable {
    let chatId: ChatId
    let groupName: String?
    let lastMessageAt: Date?
    let settings: ChatSettings

    var id: String {
        return chatId.rawValue
    }
}
