import Observation

@Observable
final class TasksListViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeUserProfile: ObserveUserProfileUseCase
    @ObservationIgnored private let observeTasks: ObserveTasksUseCase
    @ObservationIgnored private let observeCompletedTaskIds: ObserveCompletedTaskIdsUseCase
    @ObservationIgnored private let observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase
    @ObservationIgnored private let toggleTaskFavorite: ToggleTaskFavoriteUseCase
    @ObservationIgnored private let observeTaskSubmissions: ObserveTaskSubmissionsUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var uiState = TasksListUiState()

    init(
        observeSession: ObserveSessionUseCase,
        observeUserProfile: ObserveUserProfileUseCase,
        observeTasks: ObserveTasksUseCase,
        observeCompletedTaskIds: ObserveCompletedTaskIdsUseCase,
        observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase,
        toggleTaskFavorite: ToggleTaskFavoriteUseCase,
        observeTaskSubmissions: ObserveTaskSubmissionsUseCase
    ) {
        self.observeSession = observeSession
        self.observeUserProfile = observeUserProfile
        self.observeTasks = observeTasks
        self.observeCompletedTaskIds = observeCompletedTaskIds
        self.observeFavoriteTaskIds = observeFavoriteTaskIds
        self.toggleTaskFavorite = toggleTaskFavorite
        self.observeTaskSubmissions = observeTaskSubmissions
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            start(userId: session?.userId)
        }
        sessionTask.cancel()
    }

    func handle(_ action: TasksListUserAction) {
        switch action {
        case .filtersChanged(let filters):
            uiState.filters = filters
        case .queryChanged(let query):
            uiState.query = query
        case .favoriteToggled(let task):
            toggleFavorite(task)
        case .taskSelected:
            break
        case .retry:
            uiState.isLoading = true
            uiState.hasError = false
            start(userId: userId)
        }
    }

    private func start(userId: String?) {
        sessionTask.run { [weak self] in
            await self?.observeUserData(userId: userId)
        }
    }

    private func observeUserData(userId: String?) async {
        guard let userId else {
            uiState.completedTaskIds = []
            await observeTaskList()
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeTaskList() }
            group.addTask { await self.observeCompleted(userId: userId) }
            group.addTask { await self.observeSubmissions(userId: userId) }
            group.addTask { await self.observeProfile(userId: userId) }
            group.addTask { await self.observeFavorites(userId: userId) }
        }
    }

    private func observeTaskList() async {
        do {
            for try await tasks in observeTasks.execute() {
                uiState.tasks = tasks
                uiState.hasLoadedTasks = true
                finishLoadingIfReady()
            }
        } catch {
            showError()
        }
    }

    private func observeCompleted(userId: String) async {
        do {
            for try await completedTaskIds in observeCompletedTaskIds.execute(userId: userId) {
                uiState.completedTaskIds = completedTaskIds
                uiState.hasLoadedCompletedIds = true
                finishLoadingIfReady()
            }
        } catch {
            showError()
        }
    }

    private func finishLoadingIfReady() {
        let hasLoadedUserData = uiState.hasLoadedCompletedIds && uiState.hasLoadedProfile
        guard uiState.hasLoadedTasks, hasLoadedUserData || userId == nil else {
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
        uiState.hasError = uiState.tasks.isEmpty
    }

    private func observeSubmissions(userId: String) async {
        do {
            for try await submissions in observeTaskSubmissions.execute(userId: userId) {
                uiState.pendingTaskIds = Set(submissions.filter { return $0.status == .pending }.map(\.taskId))
            }
        } catch {
            uiState.pendingTaskIds = []
        }
    }

    private func observeProfile(userId: String) async {
        do {
            for try await profile in observeUserProfile.execute(userId: userId) {
                uiState.profile = profile
                uiState.hasLoadedProfile = true
                finishLoadingIfReady()
            }
        } catch {
            uiState.profile = nil
            uiState.hasLoadedProfile = true
            finishLoadingIfReady()
        }
    }

    private func observeFavorites(userId: String) async {
        do {
            for try await favoriteIds in observeFavoriteTaskIds.execute(userId: userId) {
                uiState.favoriteTaskIds = favoriteIds
            }
        } catch {
            return
        }
    }

    private func toggleFavorite(_ task: EcoTask) {
        guard let userId else {
            return
        }
        let isFavorite = uiState.favoriteTaskIds.contains(task.id)
        Task {
            try? await toggleTaskFavorite.execute(userId: userId, taskId: task.id, isFavorite: !isFavorite)
        }
    }
}
