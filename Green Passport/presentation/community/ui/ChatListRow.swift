import SwiftUI

struct ChatListRow: View {
    let chat: ChatSummary
    let onOpen: () -> Void
    let onAction: (ChatListAction) -> Void

    var body: some View {
        Button(action: onOpen) {
            ChatRow(
                chatId: chat.chatId,
                title: chat.title,
                lastMessageAt: chat.lastMessageAt,
                isPinned: chat.settings.isPinned,
                isMuted: chat.settings.isMuted
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            pinButton
                .tint(Palette.forest)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            archiveButton
                .tint(Palette.secondaryText)
            muteButton
                .tint(Palette.forest)
        }
        .contextMenu {
            pinButton
            muteButton
            archiveButton
        }
    }

    private var pinButton: some View {
        return Button {
            onAction(.togglePin)
        } label: {
            if chat.settings.isPinned {
                Label(String(localized: .unpinChat), systemImage: "pin.slash")
            } else {
                Label(String(localized: .pinChat), systemImage: "pin")
            }
        }
    }

    private var muteButton: some View {
        return Button {
            onAction(.toggleMute)
        } label: {
            if chat.settings.isMuted {
                Label(String(localized: .unmuteChat), systemImage: "bell")
            } else {
                Label(String(localized: .muteChat), systemImage: "bell.slash")
            }
        }
    }

    private var archiveButton: some View {
        return Button {
            onAction(.toggleArchive)
        } label: {
            if chat.settings.isArchived {
                Label(String(localized: .unarchiveChat), systemImage: "tray.and.arrow.up")
            } else {
                Label(String(localized: .archiveChat), systemImage: "archivebox")
            }
        }
    }
}
