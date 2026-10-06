import SwiftUI

struct EcoTipsListRoute: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: EcoTipsListViewModel

    init(container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildEcoTipsListViewModel())
    }

    var body: some View {
        EcoTipsListScreen(
            uiState: viewModel.uiState,
            query: Binding(get: { return viewModel.uiState.query }, set: viewModel.updateQuery),
            onFilter: viewModel.select,
            onTip: { router.push(.ecoTipDetail(tipId: $0.id)) },
            onToggleBookmark: viewModel.toggleBookmark,
            onRetry: viewModel.retry
        )
        .task {
            await viewModel.observe()
        }
    }
}
