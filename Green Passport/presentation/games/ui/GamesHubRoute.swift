import SwiftUI

struct GamesHubRoute: View {
    let container: AppDIContainer

    @State private var viewModel: GamesHubViewModel
    @State private var playingGame: Game?

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildGamesHubViewModel())
    }

    var body: some View {
        GamesHubScreen(
            uiState: viewModel.visibleState,
            query: Binding(get: { return viewModel.query }, set: viewModel.updateQuery),
            bestScores: viewModel.bestScores,
            onGame: { playingGame = $0 },
            onRetry: viewModel.retry
        )
        .task(id: viewModel.observationId) {
            await viewModel.observe()
        }
        .onAppear(perform: viewModel.refreshScores)
        .fullScreenCover(item: $playingGame, onDismiss: viewModel.refreshScores) { game in
            NavigationStack {
                GameWebRoute(game: game, container: container)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
