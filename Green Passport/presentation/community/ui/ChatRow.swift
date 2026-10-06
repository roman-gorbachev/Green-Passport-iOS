import SwiftUI

struct ChatRow: View {
    let chatId: ChatId
    let title: String
    var lastMessageAt: Date?
    var isPinned = false
    var isMuted = false

    var body: some View {
        ListRow(title: title, subtitle: lastMessageAt.map(Self.relativeText)) {
            SymbolTile(systemImage: chatId.systemImage)
        } trailing: {
            HStack(spacing: Spacing.xxSmall) {
                if isMuted {
                    Image(systemName: "bell.slash.fill")
                        .accessibilityLabel(Text(.muteChat))
                }
                if isPinned {
                    Image(systemName: "pin.fill")
                        .accessibilityLabel(Text(.pinChat))
                }
            }
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
        }
    }

    private static func relativeText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    List {
        ChatRow(chatId: .forum, title: "Форум", lastMessageAt: .now, isPinned: true, isMuted: true)
        ChatRow(chatId: .group(id: "1"), title: "Эко-Минск", lastMessageAt: nil)
    }
}
