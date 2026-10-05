import Foundation
import Observation

@Observable
final class TaskDetailViewModel {
    @ObservationIgnored private let taskId: String
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeTask: ObserveTaskUseCase
    @ObservationIgnored private let observeCompletedTaskIds: ObserveCompletedTaskIdsUseCase
    @ObservationIgnored private let completeSelfTask: CompleteSelfTaskUseCase
    @ObservationIgnored private let redeemTaskCode: RedeemTaskCodeUseCase
    @ObservationIgnored private let submitTaskPhoto: SubmitTaskPhotoUseCase
    @ObservationIgnored private let observeTaskSubmissions: ObserveTaskSubmissionsUseCase
    @ObservationIgnored private let observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase
    @ObservationIgnored private let toggleTaskFavorite: ToggleTaskFavoriteUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var uiState = TaskDetailUiState()

    init(
        taskId: String,
        observeSession: ObserveSessionUseCase,
        observeTask: ObserveTaskUseCase,
        observeCompletedTaskIds: ObserveCompletedTaskIdsUseCase,
        completeSelfTask: CompleteSelfTaskUseCase,
        redeemTaskCode: RedeemTaskCodeUseCase,
        submitTaskPhoto: SubmitTaskPhotoUseCase,
        observeTaskSubmissions: ObserveTaskSubmissionsUseCase,
        observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase,
        toggleTaskFavorite: ToggleTaskFavoriteUseCase
    ) {
        self.taskId = taskId
        self.observeSession = observeSession
        self.observeTask = observeTask
        self.observeCompletedTaskIds = observeCompletedTaskIds
        self.completeSelfTask = completeSelfTask
        self.redeemTaskCode = redeemTaskCode
        self.submitTaskPhoto = submitTaskPhoto
        self.observeTaskSubmissions = observeTaskSubmissions
        self.observeFavoriteTaskIds = observeFavoriteTaskIds
        self.toggleTaskFavorite = toggleTaskFavorite
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

    func completeTask() {
        runRewardAction { [taskId] in
            return try await self.completeSelfTask.execute(taskId: taskId)
        }
    }

    func redeemCode(_ code: String) {
        runRewardAction {
            return try await self.redeemTaskCode.execute(code: code)
        }
    }

    func toggleFavorite() {
        guard let userId else {
            return
        }
        let isFavorite = !uiState.isFavorite
        uiState.isFavorite = isFavorite
        Task {
            do {
                try await toggleTaskFavorite.execute(userId: userId, taskId: taskId, isFavorite: isFavorite)
            } catch {
                uiState.isFavorite = !isFavorite
            }
        }
    }

    func submitPhoto(_ imageData: Data) {
        guard let userId, !uiState.isSubmitting else {
            return
        }
        uiState.isSubmitting = true
        uiState.failure = nil
        Task {
            do {
                let submission = try await submitTaskPhoto.execute(userId: userId, taskId: taskId, imageData: imageData)
                uiState.submission = submission
                uiState.isSubmitting = false
            } catch {
                handleFailure(error)
            }
        }
    }

    private func runRewardAction(_ action: @escaping () async throws -> RewardResult) {
        guard !uiState.isCompleted, !uiState.isSubmitting, userId != nil else {
            return
        }
        uiState.isSubmitting = true
        uiState.failure = nil
        Task {
            do {
                let reward = try await action()
                uiState.isSubmitting = false
                uiState.isCompleted = true
                uiState.earnedPoints = reward.points
                uiState.streakBonus = reward.streakBonus
            } catch {
                handleFailure(error)
            }
        }
    }

    private func handleFailure(_ error: Error) {
        let failure = (error as? RewardFailureError)?.failure ?? .unknown
        uiState.isSubmitting = false
        uiState.failure = failure
        uiState.isCompleted = uiState.isCompleted || failure == .alreadyCompleted
    }

    private func observeSubmissions(userId: String) async {
        do {
            for try await submissions in observeTaskSubmissions.execute(userId: userId) {
                let submission = submissions.first { return $0.taskId == taskId }
                uiState.submission = submission
                uiState.isCompleted = uiState.isCompleted || submission?.status == .approved
            }
        } catch {
            return
        }
    }

    private func start(userId: String?) {
        sessionTask.run { [weak self] in
            await self?.observeData(userId: userId)
        }
    }

    private func observeData(userId: String?) async {
        guard let userId else {
            await observeTaskDocument()
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeTaskDocument() }
            group.addTask { await self.observeCompletion(userId: userId) }
            group.addTask { await self.observeSubmissions(userId: userId) }
            group.addTask { await self.observeFavorite(userId: userId) }
        }
    }

    private func observeTaskDocument() async {
        do {
            for try await task in observeTask.execute(taskId: taskId) {
                uiState.task = task
                uiState.isLoading = false
                uiState.hasError = false
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState.isLoading = false
            uiState.hasError = uiState.task == nil
        }
    }

    private func observeFavorite(userId: String) async {
        do {
            for try await favoriteIds in observeFavoriteTaskIds.execute(userId: userId) {
                uiState.isFavorite = favoriteIds.contains(taskId)
            }
        } catch {
            return
        }
    }

    private func observeCompletion(userId: String) async {
        do {
            for try await completedTaskIds in observeCompletedTaskIds.execute(userId: userId) {
                uiState.isCompleted = uiState.isCompleted || completedTaskIds.contains(taskId)
            }
        } catch {
            return
        }
    }
}
