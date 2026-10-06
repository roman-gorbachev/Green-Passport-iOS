import SwiftUI

struct CommunityHubRoute: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CommunityHubViewModel
    @State private var reloadId = 0

    init(container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildCommunityHubViewModel())
    }

    var body: some View {
        CommunityHubScreen(
            uiState: viewModel.uiState,
            query: Binding(get: { return viewModel.uiState.query }, set: viewModel.updateQuery),
            groupDraftName: Binding(get: { return viewModel.uiState.groupDraftName }, set: viewModel.updateGroupDraftName),
            inviteCode: Binding(get: { return viewModel.uiState.inviteCodeDraft }, set: viewModel.updateInviteCodeDraft),
            onOpenChat: { router.push($0.destination) },
            onOpenArchive: { router.push(.archivedChats) },
            onChatAction: { action, chat in viewModel.handle(action, on: chat) },
            onCreateGroup: viewModel.createGroupFromDraft,
            onJoinByCode: joinByCode,
            onDismissGroupNameRejected: viewModel.dismissGroupNameRejected,
            onDismissInviteCodeNotFound: viewModel.dismissInviteCodeNotFound,
            onRetry: {
                viewModel.retry()
                reloadId += 1
            }
        )
        .task(id: reloadId) {
            await viewModel.observe()
        }
    }

    private func joinByCode() {
        Task {
            if let groupId = await viewModel.joinByCode() {
                router.push(.group(id: groupId))
            }
        }
    }
}
