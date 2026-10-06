import Foundation

extension ComposerMode {
    var banner: ComposerBanner? {
        switch self {
        case .new:
            return nil
        case .reply(let quote):
            return ComposerBanner(
                systemImage: "arrowshape.turn.up.left",
                title: String(localized: .replyingToFormat(quote.senderName ?? String(localized: .guest))),
                text: quote.text
            )
        case .edit:
            return ComposerBanner(systemImage: "pencil", title: String(localized: .editingMessage), text: nil)
        }
    }
}
