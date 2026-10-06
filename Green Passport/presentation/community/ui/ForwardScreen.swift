import SwiftUI

struct ForwardScreen: View {
    let uiState: ForwardUiState
    let onForward: (ChatId) -> Void

    var body: some View {
        List {
            Group {
                Section {
                    chatButton(chatId: .forum, title: String(localized: .communityForumTitle))
                    ForEach(uiState.groups) { group in
                        chatButton(chatId: .group(id: group.id), title: group.name)
                    }
                } footer: {
                    if let failure = failureMessage {
                        Text(failure)
                            .foregroundStyle(Palette.error)
                    }
                }
            }
            .themedRowBackground()
        }
        .listStyle(.insetGrouped)
        .themedListBackground()
        .overlay {
            if uiState.isLoading {
                StateView(kind: .loading)
            }
        }
        .navigationTitle(Text(.forwardTo))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var failureMessage: LocalizedStringResource? {
        if uiState.isTextRejected {
            return .textContainsBannedWords
        }
        if uiState.isSendFailed {
            return .messageNotSentMsg
        }
        return nil
    }

    private func chatButton(chatId: ChatId, title: String) -> some View {
        return Button {
            onForward(chatId)
        } label: {
            ChatRow(chatId: chatId, title: title)
                .loadingOverlay(uiState.sendingChatId == chatId, tint: Palette.forest)
        }
        .buttonStyle(.plain)
        .disabled(uiState.sendingChatId != nil)
    }
}

#Preview {
    NavigationStack {
        ForwardScreen(
            uiState: ForwardUiState(
                groups: [CommunityGroup(id: "1", name: "Эко-Минск", memberIds: ["1"])],
                isLoading: false
            ),
            onForward: { _ in }
        )
    }
}
