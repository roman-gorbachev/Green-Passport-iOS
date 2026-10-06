import SwiftUI

struct CommunityHubScreen: View {
    private static let archiveRevealDistance: CGFloat = 60
    private static let archiveHideDistance: CGFloat = 80

    let uiState: CommunityHubUiState
    @Binding var query: String
    @Binding var groupDraftName: String
    @Binding var inviteCode: String
    let onOpenChat: (ChatId) -> Void
    let onOpenArchive: () -> Void
    let onChatAction: (ChatListAction, ChatSummary) -> Void
    let onCreateGroup: () -> Void
    let onJoinByCode: () -> Void
    let onDismissGroupNameRejected: () -> Void
    let onDismissInviteCodeNotFound: () -> Void
    let onRetry: () -> Void

    @State private var isArchiveRevealed = false
    @State private var isCreatePromptPresented = false
    @State private var isCodePromptPresented = false

    var body: some View {
        List {
            if uiState.isSearching {
                searchResults
            } else {
                if isArchiveRevealed && uiState.archivedCount > 0 {
                    Section {
                        archiveRow
                    }
                }
                Section {
                    forumRow
                } header: {
                    Text(.communityForumTitle)
                }
                Section {
                    if uiState.hasError {
                        StateView(kind: .error(retry: onRetry))
                    } else if uiState.groups.isEmpty && !uiState.isLoading {
                        Text(.myGroupsEmptyMsg)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                    } else {
                        ForEach(uiState.groups) { chat in
                            ChatListRow(chat: chat) {
                                onOpenChat(chat.chatId)
                            } onAction: { action in
                                onChatAction(action, chat)
                            }
                        }
                    }
                } header: {
                    Text(.myGroups)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: Text(.searchGroupsPlaceholder))
        .scrollDismissesKeyboard(.interactively)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            updateArchiveVisibility(offset: offset)
        }
        .animation(.snappy, value: uiState.groups)
        .animation(.snappy, value: isArchiveRevealed)
        .navigationTitle(Text(.community))
        .toolbar {
            if uiState.currentUserId != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                }
            }
        }
        .alert(Text(.createGroup), isPresented: $isCreatePromptPresented) {
            TextField(String(localized: .groupsDraftLabel), text: $groupDraftName)
            Button(role: .cancel) {
                groupDraftName = ""
            } label: {
                Text(.cancel)
            }
            Button(action: onCreateGroup) {
                Text(.groupsCreateButton)
            }
        }
        .alert(Text(.joinByCode), isPresented: $isCodePromptPresented) {
            TextField(String(localized: .inviteCode), text: $inviteCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button(role: .cancel) {
                inviteCode = ""
            } label: {
                Text(.cancel)
            }
            Button(action: onJoinByCode) {
                Text(.groupsJoinButton)
            }
        }
        .alert(
            Text(.textContainsBannedWords),
            isPresented: Binding(get: { return uiState.isGroupNameRejected }, set: { _ in onDismissGroupNameRejected() })
        ) {
            Button(role: .cancel, action: onDismissGroupNameRejected) {
                Text(.close)
            }
        }
        .alert(
            Text(.groupNotFoundMsg),
            isPresented: Binding(get: { return uiState.isInviteCodeNotFound }, set: { _ in onDismissInviteCodeNotFound() })
        ) {
            Button(role: .cancel, action: onDismissInviteCodeNotFound) {
                Text(.close)
            }
        }
    }

    private var addMenu: some View {
        return Menu {
            Button {
                isCreatePromptPresented = true
            } label: {
                Label(String(localized: .createGroup), systemImage: "plus.bubble")
            }
            Button {
                isCodePromptPresented = true
            } label: {
                Label(String(localized: .joinByCode), systemImage: "number")
            }
        } label: {
            Label(String(localized: .createGroup), systemImage: "plus")
                .loadingOverlay(uiState.isCreatingGroup || uiState.isJoiningByCode)
        }
        .disabled(uiState.isCreatingGroup || uiState.isJoiningByCode)
    }

    private var archiveRow: some View {
        return Button(action: onOpenArchive) {
            ListRow(title: String(localized: .archivedChats)) {
                SymbolTile(systemImage: "archivebox.fill", style: .muted)
            } trailing: {
                HStack(spacing: Spacing.xSmall) {
                    Text(uiState.archivedCount, format: .number)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var forumRow: some View {
        return Button {
            onOpenChat(.forum)
        } label: {
            ChatRow(
                chatId: .forum,
                title: String(localized: .communityForumTitle),
                lastMessageAt: uiState.forum.lastMessageAt,
                isMuted: uiState.forum.settings.isMuted
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if uiState.currentUserId != nil {
                Button {
                    onChatAction(.toggleMute, uiState.forum)
                } label: {
                    if uiState.forum.settings.isMuted {
                        Label(String(localized: .unmuteChat), systemImage: "bell")
                    } else {
                        Label(String(localized: .muteChat), systemImage: "bell.slash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if uiState.myGroupMatches.isEmpty && uiState.otherGroupMatches.isEmpty {
            Text(.groupsNotFound)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
        }
        if !uiState.myGroupMatches.isEmpty {
            Section {
                ForEach(uiState.myGroupMatches) { result in
                    searchRow(result)
                }
            } header: {
                Text(.myGroups)
            }
        }
        if !uiState.otherGroupMatches.isEmpty {
            Section {
                ForEach(uiState.otherGroupMatches) { result in
                    searchRow(result)
                }
            } header: {
                Text(.otherGroups)
            }
        }
    }

    private func searchRow(_ result: GroupSearchResult) -> some View {
        let subtitle = result.matchedMemberName.map { return String(localized: .memberMatchFormat($0)) }
            ?? String(localized: .groupsMemberCountFormat(result.group.memberIds.count))
        return Button {
            onOpenChat(.group(id: result.group.id))
        } label: {
            ListRow(title: result.group.name, subtitle: subtitle) {
                SymbolTile(systemImage: ChatId.group(id: result.group.id).systemImage)
            } trailing: {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .buttonStyle(.plain)
    }

    private func updateArchiveVisibility(offset: CGFloat) {
        if offset < -Self.archiveRevealDistance && !isArchiveRevealed {
            isArchiveRevealed = true
        } else if offset > Self.archiveHideDistance && isArchiveRevealed {
            isArchiveRevealed = false
        }
    }
}

#Preview {
    NavigationStack {
        CommunityHubScreen(
            uiState: CommunityHubUiState(
                groups: [ChatSummary(chatId: .group(id: "1"), groupName: "Эко-Минск", lastMessageAt: .now, settings: .defaults(for: .group(id: "1")))],
                archivedCount: 1,
                currentUserId: "1",
                isLoading: false
            ),
            query: .constant(""),
            groupDraftName: .constant(""),
            inviteCode: .constant(""),
            onOpenChat: { _ in },
            onOpenArchive: {},
            onChatAction: { _, _ in },
            onCreateGroup: {},
            onJoinByCode: {},
            onDismissGroupNameRejected: {},
            onDismissInviteCodeNotFound: {},
            onRetry: {}
        )
    }
}
