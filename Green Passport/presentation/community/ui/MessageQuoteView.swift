import SwiftUI

struct MessageQuoteView: View {
    private static let barWidth: CGFloat = 3

    let quote: MessageQuote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xSmall) {
                Capsule()
                    .fill(Palette.forest)
                    .frame(width: Self.barWidth)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(quote.senderName ?? String(localized: .guest))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                    Text(quote.isDeleted ? String(localized: .messageDeleted) : quote.text)
                        .font(.caption)
                        .italic(quote.isDeleted)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MessageQuoteView(quote: MessageQuote(messageId: "1", senderName: "Аня", text: "Кто идёт на субботник?"), onTap: {})
        .padding()
}
