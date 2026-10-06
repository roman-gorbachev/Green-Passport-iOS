import SwiftUI

struct GamesHubScreen: View {
    private static let columnCount = 2

    let uiState: ListUiState<Game>
    @Binding var query: String
    let bestScores: [String: Int]
    let onGame: (Game) -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch uiState {
            case .loading:
                StateView(kind: .loading)
            case .error:
                StateView(kind: .error(retry: onRetry))
            case .success(let games) where games.isEmpty && !query.isBlankSearchQuery:
                StateView(kind: .empty(message: .nothingFound))
            case .success(let games):
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.medium, alignment: .top), count: Self.columnCount),
                        alignment: .leading,
                        spacing: Spacing.large
                    ) {
                        ForEach(games) { game in
                            Button {
                                onGame(game)
                            } label: {
                                GameTile(game: game, bestScore: bestScores[game.id])
                            }
                            .buttonStyle(GameTileButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.xSmall)
                    .padding(.bottom, Spacing.large)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.screenBackground)
        .dismissesKeyboardOnBackgroundTap()
        .bottomSearchable(text: $query, prompt: .searchGamesPlaceholder)
        .navigationTitle(Text(.games))
    }
}

#Preview {
    NavigationStack {
        GamesHubScreen(
            uiState: .success(data: [
                Game(id: "eco_runner", titles: ["ru": "Эко-забег"], path: "eco_runner/index.html", sfSymbol: "figure.run", iconEmoji: "🏃", iconColors: ["#34C77B", "#1F6B47"], maxPoints: 30, order: 1),
                Game(id: "bee_garden", titles: ["ru": "Опылитель"], path: "bee_garden/index.html", sfSymbol: "leaf.fill", iconEmoji: "🐝", iconColors: ["#FFB703", "#FB8500"], maxPoints: 30, order: 2),
            ]),
            query: .constant(""),
            bestScores: ["eco_runner": 18],
            onGame: { _ in },
            onRetry: {}
        )
    }
}
