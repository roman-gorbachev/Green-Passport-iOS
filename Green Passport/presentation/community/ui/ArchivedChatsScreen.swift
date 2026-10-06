import SwiftUI

struct ArchivedChatsScreen: View {
    let uiState: ChatListUiState
    let onOpenChat: (ChatId) -> Void
    let onChatAction: (ChatListAction, ChatSummary) -> Void

    var body: some View {
        List(uiState.chats) { chat in
            ChatListRow(chat: chat) {
                onOpenChat(chat.chatId)
            } onAction: { action in
                onChatAction(action, chat)
            }
        }
        .listStyle(.insetGrouped)
        .animation(.snappy, value: uiState.chats)
        .navigationTitle(Text(.archivedChats))
    }
}

#Preview {
    NavigationStack {
        ArchivedChatsScreen(
            uiState: ChatListUiState(
                chats: [ChatSummary(chatId: .forum, groupName: nil, lastMessageAt: .now, settings: ChatSettings(chatId: .forum, isPinned: false, isArchived: true, isMuted: true))],
                isLoading: false
            ),
            onOpenChat: { _ in },
            onChatAction: { _, _ in }
        )
    }
}
