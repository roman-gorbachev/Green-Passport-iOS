import SwiftUI

struct ArchivedChatsScreen: View {
    let uiState: ChatListUiState
    let onOpenChat: (ChatId) -> Void
    let onChatAction: (ChatListAction, ChatSummary) -> Void

    var body: some View {
        List(uiState.chats) { chat in
            Group {
                ChatListRow(chat: chat) {
                    onOpenChat(chat.chatId)
                } onAction: { action in
                    onChatAction(action, chat)
                }
            }
            .themedRowBackground()
        }
        .listStyle(.insetGrouped)
        .themedListBackground()
        .animation(.snappy, value: uiState.chats)
        .navigationTitle(Text(.archivedChats))
    }
}

#Preview {
    NavigationStack {
        ArchivedChatsScreen(
            uiState: ChatListUiState(
                chats: [ChatSummary(chatId: .group(id: "1"), groupName: "Эко-Минск", lastMessageAt: .now, settings: ChatSettings(chatId: .group(id: "1"), isPinned: false, isArchived: true, isMuted: false))],
                isLoading: false
            ),
            onOpenChat: { _ in },
            onChatAction: { _, _ in }
        )
    }
}
