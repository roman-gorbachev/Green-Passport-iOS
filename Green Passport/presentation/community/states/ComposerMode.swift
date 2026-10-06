enum ComposerMode: Hashable {
    case new
    case reply(MessageQuote)
    case edit(messageId: String)
}
