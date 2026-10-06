import SwiftUI

struct GroupDetailRoute: View {
    let container: AppDIContainer

    @State private var viewModel: GroupDetailViewModel
    @State private var settingsViewModel: ChatSettingsViewModel
    @State private var forwardedMessage: MessageTarget?
    @State private var reloadId = 0

    init(groupId: String, container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildGroupDetailViewModel(groupId: groupId))
        _settingsViewModel = State(initialValue: container.buildChatSettingsViewModel(chatId: .group(id: groupId)))
    }

    var body: some View {
        GroupDetailScreen(
            uiState: viewModel.uiState,
            draft: Binding(get: { return viewModel.uiState.draft }, set: viewModel.updateDraft),
            onSend: viewModel.send,
            onJoin: viewModel.join,
            onLeave: viewModel.leave,
            onLoadMembers: viewModel.loadMembers,
            onRetryMessages: viewModel.retryMessages,
            onMessageAction: { action, target in
                if action == .forward {
                    forwardedMessage = target
                } else {
                    viewModel.handle(action, on: target)
                }
            },
            onCancelComposerMode: viewModel.cancelComposerMode,
            isMuted: settingsViewModel.settings.isMuted,
            onToggleMute: settingsViewModel.toggleMute,
            onRetry: { reloadId += 1 }
        )
        .task(id: reloadId) {
            await viewModel.observe()
        }
        .task {
            await settingsViewModel.observe()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.copiedCount)
        .sheet(item: $forwardedMessage) { message in
            ForwardRoute(message: message, container: container)
        }
    }
}
