import SwiftUI

struct ForumRoute: View {
    let container: AppDIContainer

    @State private var viewModel: ForumViewModel
    @State private var settingsViewModel: ChatSettingsViewModel
    @State private var forwardedMessage: MessageTarget?
    @State private var reloadId = 0

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildForumViewModel())
        _settingsViewModel = State(initialValue: container.buildChatSettingsViewModel(chatId: .forum))
    }

    var body: some View {
        ForumScreen(
            uiState: viewModel.uiState,
            draft: Binding(get: { return viewModel.uiState.draft }, set: viewModel.updateDraft),
            onPost: viewModel.post,
            onReport: viewModel.report,
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
        .sensoryFeedback(.success, trigger: viewModel.postedCount)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.copiedCount)
        .sheet(item: $forwardedMessage) { message in
            ForwardRoute(message: message, container: container)
        }
    }
}
