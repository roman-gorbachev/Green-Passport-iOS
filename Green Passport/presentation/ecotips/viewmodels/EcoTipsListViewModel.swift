import Observation

@Observable
final class EcoTipsListViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeEcoTips: ObserveEcoTipsUseCase
    @ObservationIgnored private let observeReadTipIds: ObserveReadTipIdsUseCase
    @ObservationIgnored private let observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase
    @ObservationIgnored private let toggleTipBookmark: ToggleTipBookmarkUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var uiState = EcoTipsListUiState()

    init(
        observeSession: ObserveSessionUseCase,
        observeEcoTips: ObserveEcoTipsUseCase,
        observeReadTipIds: ObserveReadTipIdsUseCase,
        observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase,
        toggleTipBookmark: ToggleTipBookmarkUseCase
    ) {
        self.observeSession = observeSession
        self.observeEcoTips = observeEcoTips
        self.observeReadTipIds = observeReadTipIds
        self.observeBookmarkedTipIds = observeBookmarkedTipIds
        self.toggleTipBookmark = toggleTipBookmark
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            start(userId: session?.userId)
        }
        sessionTask.cancel()
    }

    func retry() {
        uiState.isLoading = true
        uiState.hasError = false
        start(userId: userId)
    }

    func updateQuery(_ query: String) {
        uiState.query = query
    }

    func select(_ filter: EcoTipFilter) {
        uiState.filter = filter
    }

    func toggleBookmark(_ tip: EcoTip) {
        guard let userId else {
            return
        }
        let isBookmarked = uiState.bookmarkedTipIds.contains(tip.id)
        Task {
            try? await toggleTipBookmark.execute(userId: userId, tipId: tip.id, isBookmarked: !isBookmarked)
        }
    }

    private func start(userId: String?) {
        sessionTask.run { [weak self] in
            await self?.observeData(userId: userId)
        }
    }

    private func observeData(userId: String?) async {
        guard let userId else {
            await observeTips()
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeTips() }
            group.addTask { await self.observeReadIds(userId: userId) }
            group.addTask { await self.observeBookmarks(userId: userId) }
        }
    }

    private func observeTips() async {
        do {
            for try await tips in observeEcoTips.execute() {
                uiState.tips = tips
                uiState.isLoading = false
                uiState.hasError = false
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState.isLoading = false
            uiState.hasError = uiState.tips.isEmpty
        }
    }

    private func observeReadIds(userId: String) async {
        do {
            for try await ids in observeReadTipIds.execute(userId: userId) {
                uiState.readTipIds = ids
            }
        } catch {
            return
        }
    }

    private func observeBookmarks(userId: String) async {
        do {
            for try await ids in observeBookmarkedTipIds.execute(userId: userId) {
                uiState.bookmarkedTipIds = ids
            }
        } catch {
            return
        }
    }
}
