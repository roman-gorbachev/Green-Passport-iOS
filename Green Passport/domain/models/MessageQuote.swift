import Foundation

nonisolated struct MessageQuote: Hashable, Sendable {
    private static let maximumTextLength = 200

    let messageId: String
    let senderName: String?
    let text: String

    var isDeleted: Bool {
        return text.isEmpty
    }

    static func make(messageId: String, senderName: String?, text: String) -> MessageQuote {
        return MessageQuote(messageId: messageId, senderName: senderName, text: String(text.prefix(maximumTextLength)))
    }
}
