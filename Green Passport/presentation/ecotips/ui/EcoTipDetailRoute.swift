import SwiftUI

struct EcoTipDetailRoute: View {
    @State private var viewModel: EcoTipDetailViewModel

    init(tipId: String, container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildEcoTipDetailViewModel(tipId: tipId))
    }

    var body: some View {
        EcoTipDetailScreen(
            uiState: viewModel.uiState,
            onMarkRead: viewModel.markRead,
            onToggleBookmark: viewModel.toggleBookmark,
            onRetry: viewModel.retry
        )
        .task {
            await viewModel.observe()
        }
    }
}
