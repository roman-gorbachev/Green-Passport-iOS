import Observation

@Observable
final class EcoTipDetailViewModel {
    @ObservationIgnored private let tipId: String
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeEcoTips: ObserveEcoTipsUseCase
    @ObservationIgnored private let observeReadTipIds: ObserveReadTipIdsUseCase
    @ObservationIgnored private let markTipRead: MarkTipReadUseCase
    @ObservationIgnored private let observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase
    @ObservationIgnored private let toggleTipBookmark: ToggleTipBookmarkUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var uiState = EcoTipDetailUiState()

    init(
        tipId: String,
        observeSession: ObserveSessionUseCase,
        observeEcoTips: ObserveEcoTipsUseCase,
        observeReadTipIds: ObserveReadTipIdsUseCase,
        markTipRead: MarkTipReadUseCase,
        observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase,
        toggleTipBookmark: ToggleTipBookmarkUseCase
    ) {
        self.tipId = tipId
        self.observeSession = observeSession
        self.observeEcoTips = observeEcoTips
        self.observeReadTipIds = observeReadTipIds
        self.markTipRead = markTipRead
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

    func markRead() {
        guard userId != nil, !uiState.isRead, !uiState.isSubmitting else {
            return
        }
        uiState.isSubmitting = true
        uiState.failure = nil
        Task {
            do {
                let reward = try await markTipRead.execute(tipId: tipId)
                uiState.isRead = true
                uiState.streakBonus = reward.streakBonus
            } catch {
                uiState.failure = (error as? RewardFailureError)?.failure ?? .unknown
            }
            uiState.isSubmitting = false
        }
    }

    func toggleBookmark() {
        guard let userId else {
            return
        }
        let isBookmarked = !uiState.isBookmarked
        uiState.isBookmarked = isBookmarked
        Task {
            do {
                try await toggleTipBookmark.execute(userId: userId, tipId: tipId, isBookmarked: isBookmarked)
            } catch {
                uiState.isBookmarked = !isBookmarked
            }
        }
    }

    private func start(userId: String?) {
        sessionTask.run { [weak self] in
            await self?.observeData(userId: userId)
        }
    }

    private func observeData(userId: String?) async {
        guard let userId else {
            await observeTip()
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeTip() }
            group.addTask { await self.observeReadState(userId: userId) }
            group.addTask { await self.observeBookmark(userId: userId) }
        }
    }

    private func observeTip() async {
        do {
            for try await tips in observeEcoTips.execute() {
                let tip = tips.first { return $0.id == tipId }
                uiState.tip = tip
                uiState.isLoading = false
                uiState.hasError = tip == nil
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState.isLoading = false
            uiState.hasError = uiState.tip == nil
        }
    }

    private func observeBookmark(userId: String) async {
        do {
            for try await bookmarkedIds in observeBookmarkedTipIds.execute(userId: userId) {
                uiState.isBookmarked = bookmarkedIds.contains(tipId)
            }
        } catch {
            return
        }
    }

    private func observeReadState(userId: String) async {
        do {
            for try await readIds in observeReadTipIds.execute(userId: userId) {
                uiState.isRead = uiState.isRead || readIds.contains(tipId)
            }
        } catch {
            return
        }
    }
}
