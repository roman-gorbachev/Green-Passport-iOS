import SwiftUI

struct CommunityHubRoute: View {
    @Environment(TabRouter.self) private var router
    @State private var viewModel: ChatListViewModel

    init(container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildChatListViewModel(showsArchived: false))
    }

    var body: some View {
        CommunityHubScreen(
            uiState: viewModel.uiState,
            onOpenChat: { router.push($0.destination) },
            onOpenArchive: { router.push(.archivedChats) },
            onOpenGroups: { router.push(.groups) },
            onChatAction: { action, chat in viewModel.handle(action, on: chat) },
            onRetry: viewModel.retry
        )
        .task {
            await viewModel.observe()
        }
    }
}
