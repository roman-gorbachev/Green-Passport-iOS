import Observation

@Observable
final class GamesHubViewModel {
    @ObservationIgnored private let observeGames: ObserveGamesUseCase
    @ObservationIgnored private let fetchBestScores: FetchBestScoresUseCase

    private(set) var uiState: ListUiState<Game> = .loading
    private(set) var bestScores: [String: Int] = [:]
    private(set) var observationId = 0
    private(set) var query = ""

    var visibleState: ListUiState<Game> {
        guard case .success(let games) = uiState else {
            return uiState
        }
        return .success(data: games.filter { return $0.title.matchesSearchQuery(query) })
    }

    init(observeGames: ObserveGamesUseCase, fetchBestScores: FetchBestScoresUseCase) {
        self.observeGames = observeGames
        self.fetchBestScores = fetchBestScores
    }

    func observe() async {
        bestScores = fetchBestScores.execute()
        do {
            for try await games in observeGames.execute() {
                uiState = .success(data: games)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState = .error
        }
    }

    func retry() {
        uiState = .loading
        observationId += 1
    }

    func updateQuery(_ query: String) {
        self.query = query
    }

    func refreshScores() {
        bestScores = fetchBestScores.execute()
    }
}
