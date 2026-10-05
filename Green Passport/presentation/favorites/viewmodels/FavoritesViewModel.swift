import Observation

@Observable
final class FavoritesViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeTasks: ObserveTasksUseCase
    @ObservationIgnored private let observeEcoTips: ObserveEcoTipsUseCase
    @ObservationIgnored private let observeMapPoints: ObserveMapPointsUseCase
    @ObservationIgnored private let observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase
    @ObservationIgnored private let observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase
    @ObservationIgnored private let savedMapPointIds: SavedMapPointIdsUseCase
    @ObservationIgnored private let toggleSavedMapPoint: ToggleSavedMapPointUseCase
    @ObservationIgnored private let toggleTaskFavorite: ToggleTaskFavoriteUseCase
    @ObservationIgnored private let toggleTipBookmark: ToggleTipBookmarkUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?
    @ObservationIgnored private var loadedSources: Set<FavoritesSource> = []

    private(set) var uiState = FavoritesUiState()

    init(
        observeSession: ObserveSessionUseCase,
        observeTasks: ObserveTasksUseCase,
        observeEcoTips: ObserveEcoTipsUseCase,
        observeMapPoints: ObserveMapPointsUseCase,
        observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase,
        observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase,
        savedMapPointIds: SavedMapPointIdsUseCase,
        toggleSavedMapPoint: ToggleSavedMapPointUseCase,
        toggleTaskFavorite: ToggleTaskFavoriteUseCase,
        toggleTipBookmark: ToggleTipBookmarkUseCase
    ) {
        self.observeSession = observeSession
        self.observeTasks = observeTasks
        self.observeEcoTips = observeEcoTips
        self.observeMapPoints = observeMapPoints
        self.observeFavoriteTaskIds = observeFavoriteTaskIds
        self.observeBookmarkedTipIds = observeBookmarkedTipIds
        self.savedMapPointIds = savedMapPointIds
        self.toggleSavedMapPoint = toggleSavedMapPoint
        self.toggleTaskFavorite = toggleTaskFavorite
        self.toggleTipBookmark = toggleTipBookmark
    }

    func refreshSavedPlaces() {
        uiState.savedMapPointIds = savedMapPointIds.execute()
    }

    func toggleSavedPlace(_ point: MapPoint) {
        let isSaved = !uiState.savedMapPointIds.contains(point.id)
        toggleSavedMapPoint.execute(pointId: point.id, isSaved: isSaved)
        uiState.savedMapPointIds = savedMapPointIds.execute()
    }

    func removeTask(_ task: EcoTask) {
        guard let userId else {
            return
        }
        uiState.favoriteTaskIds.remove(task.id)
        Task {
            do {
                try await toggleTaskFavorite.execute(userId: userId, taskId: task.id, isFavorite: false)
            } catch {
                uiState.favoriteTaskIds.insert(task.id)
            }
        }
    }

    func removeTip(_ tip: EcoTip) {
        guard let userId else {
            return
        }
        uiState.bookmarkedTipIds.remove(tip.id)
        Task {
            do {
                try await toggleTipBookmark.execute(userId: userId, tipId: tip.id, isBookmarked: false)
            } catch {
                uiState.bookmarkedTipIds.insert(tip.id)
            }
        }
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            guard let userId = session?.userId else {
                sessionTask.cancel()
                uiState = FavoritesUiState(isLoading: false)
                continue
            }
            start(userId: userId)
        }
        sessionTask.cancel()
    }

    func retry() {
        guard let userId else {
            return
        }
        uiState.isLoading = true
        uiState.hasError = false
        start(userId: userId)
    }

    private func start(userId: String) {
        loadedSources = []
        uiState.savedMapPointIds = savedMapPointIds.execute()
        sessionTask.run { [weak self] in
            await self?.observeUserData(userId: userId)
        }
    }

    private func observeUserData(userId: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeTaskList() }
            group.addTask { await self.observeTipList() }
            group.addTask { await self.observePlaceList() }
            group.addTask { await self.observeFavorites(userId: userId) }
            group.addTask { await self.observeBookmarks(userId: userId) }
        }
    }

    private func observeTaskList() async {
        do {
            for try await tasks in observeTasks.execute() {
                uiState.tasks = tasks
                markLoaded(.tasks)
            }
        } catch {
            showError()
        }
    }

    private func observeTipList() async {
        do {
            for try await tips in observeEcoTips.execute() {
                uiState.tips = tips
                markLoaded(.tips)
            }
        } catch {
            showError()
        }
    }

    private func observePlaceList() async {
        do {
            for try await points in observeMapPoints.execute() {
                uiState.mapPoints = points
                markLoaded(.places)
            }
        } catch {
            showError()
        }
    }

    private func observeFavorites(userId: String) async {
        do {
            for try await ids in observeFavoriteTaskIds.execute(userId: userId) {
                uiState.favoriteTaskIds = ids
                markLoaded(.favoriteTaskIds)
            }
        } catch {
            showError()
        }
    }

    private func observeBookmarks(userId: String) async {
        do {
            for try await ids in observeBookmarkedTipIds.execute(userId: userId) {
                uiState.bookmarkedTipIds = ids
                markLoaded(.bookmarkedTipIds)
            }
        } catch {
            showError()
        }
    }

    private func markLoaded(_ source: FavoritesSource) {
        loadedSources.insert(source)
        guard loadedSources.count == FavoritesSource.allCases.count else {
            return
        }
        uiState.isLoading = false
        uiState.hasError = false
    }

    private func showError() {
        guard !Task.isCancelled else {
            return
        }
        uiState.isLoading = false
        uiState.hasError = true
    }
}
