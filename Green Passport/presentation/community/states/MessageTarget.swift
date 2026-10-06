struct MessageTarget: Identifiable, Hashable {
    let id: String
    let senderName: String?
    let text: String
    let isOwn: Bool
    let isDeleted: Bool
    let canReport: Bool
    let forwardedFrom: ForwardOrigin?

    var quote: MessageQuote {
        return MessageQuote.make(messageId: id, senderName: senderName, text: text)
    }

    var forwardOrigin: ForwardOrigin {
        return forwardedFrom ?? ForwardOrigin(senderName: senderName)
    }
}
