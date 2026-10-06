import SwiftUI

struct ArchivedChatsRoute: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: ChatListViewModel

    init(container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildChatListViewModel())
    }

    var body: some View {
        ArchivedChatsScreen(
            uiState: viewModel.uiState,
            onOpenChat: { router.push($0.destination) },
            onChatAction: { action, chat in viewModel.handle(action, on: chat) }
        )
        .task {
            await viewModel.observe()
        }
    }
}
