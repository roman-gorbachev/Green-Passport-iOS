import SwiftUI

struct MessageContentView: View {
    let text: String
    let isDeleted: Bool
    let replyTo: MessageQuote?
    let forwardedFrom: ForwardOrigin?
    let onQuoteTap: (String) -> Void

    var body: some View {
        if isDeleted {
            Text(.messageDeleted)
                .font(.body)
                .italic()
                .foregroundStyle(Palette.secondaryText)
        } else {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                if let forwardedFrom {
                    Label {
                        Text(.forwardedFromFormat(forwardedFrom.senderName ?? String(localized: .guest)))
                    } icon: {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.forest)
                }
                if let replyTo {
                    MessageQuoteView(quote: replyTo) {
                        onQuoteTap(replyTo.messageId)
                    }
                }
                Text(text)
                    .font(.body)
            }
        }
    }
}

#Preview {
    MessageContentView(
        text: "Я иду!",
        isDeleted: false,
        replyTo: MessageQuote(messageId: "1", senderName: "Аня", text: "Кто идёт на субботник?"),
        forwardedFrom: ForwardOrigin(senderName: "Олег"),
        onQuoteTap: { _ in }
    )
    .padding()
}
