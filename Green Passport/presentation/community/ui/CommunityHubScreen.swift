import SwiftUI

struct CommunityHubScreen: View {
    let uiState: ChatListUiState
    let onOpenChat: (ChatId) -> Void
    let onOpenArchive: () -> Void
    let onOpenGroups: () -> Void
    let onChatAction: (ChatListAction, ChatSummary) -> Void
    let onRetry: () -> Void

    var body: some View {
        List {
            Section {
                if uiState.hasError {
                    StateView(kind: .error(retry: onRetry))
                } else {
                    ForEach(uiState.chats) { chat in
                        ChatListRow(chat: chat) {
                            onOpenChat(chat.chatId)
                        } onAction: { action in
                            onChatAction(action, chat)
                        }
                    }
                }
            } header: {
                Text(.chats)
            }
            Section {
                if uiState.archivedCount > 0 {
                    navigationRow(title: String(localized: .archivedChats), systemImage: "archivebox.fill", count: uiState.archivedCount, action: onOpenArchive)
                }
                navigationRow(title: String(localized: .communityGroupsTitle), systemImage: "person.3.fill", count: nil, action: onOpenGroups)
            }
        }
        .listStyle(.insetGrouped)
        .animation(.snappy, value: uiState.chats)
        .navigationTitle(Text(.community))
    }

    private func navigationRow(title: String, systemImage: String, count: Int?, action: @escaping () -> Void) -> some View {
        return Button(action: action) {
            ListRow(title: title) {
                SymbolTile(systemImage: systemImage, style: .muted)
            } trailing: {
                HStack(spacing: Spacing.xSmall) {
                    if let count {
                        Text(count, format: .number)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CommunityHubScreen(
            uiState: ChatListUiState(
                chats: [
                    ChatSummary(chatId: .forum, groupName: nil, lastMessageAt: .now, settings: ChatSettings(chatId: .forum, isPinned: true, isArchived: false, isMuted: true)),
                    ChatSummary(chatId: .group(id: "1"), groupName: "Эко-Минск", lastMessageAt: .now, settings: .defaults(for: .group(id: "1"))),
                ],
                archivedCount: 1,
                isLoading: false
            ),
            onOpenChat: { _ in },
            onOpenArchive: {},
            onOpenGroups: {},
            onChatAction: { _, _ in },
            onRetry: {}
        )
    }
}
