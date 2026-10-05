import Foundation
import Observation

@Observable
final class CalendarViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeEvents: ObserveEventsUseCase
    @ObservationIgnored private let observeRegisteredEventIds: ObserveRegisteredEventIdsUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var hasChosenInitialDay = false

    private(set) var uiState: ListUiState<EcoEvent> = .loading
    private(set) var registeredEventIds: Set<String> = []
    private(set) var selectedDay = DateComponents.day(containing: .now)
    private(set) var observationId = 0

    init(
        observeSession: ObserveSessionUseCase,
        observeEvents: ObserveEventsUseCase,
        observeRegisteredEventIds: ObserveRegisteredEventIdsUseCase
    ) {
        self.observeSession = observeSession
        self.observeEvents = observeEvents
        self.observeRegisteredEventIds = observeRegisteredEventIds
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeEventList() }
            group.addTask { await self.observeRegistrations() }
        }
    }

    func selectDay(_ day: DateComponents) {
        selectedDay = day
    }

    func retry() {
        uiState = .loading
        observationId += 1
    }

    private func observeEventList() async {
        do {
            for try await events in observeEvents.execute() {
                chooseInitialDay(from: events)
                uiState = .success(data: events)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState = .error
        }
    }

    private func observeRegistrations() async {
        for await session in observeSession.execute() {
            registeredEventIds = []
            guard let userId = session?.userId else {
                sessionTask.cancel()
                continue
            }
            sessionTask.run { [weak self] in
                await self?.observeRegisteredIds(userId: userId)
            }
        }
        sessionTask.cancel()
    }

    private func observeRegisteredIds(userId: String) async {
        do {
            for try await ids in observeRegisteredEventIds.execute(userId: userId) {
                registeredEventIds = ids
            }
        } catch {
            return
        }
    }

    private func chooseInitialDay(from events: [EcoEvent]) {
        guard !hasChosenInitialDay else {
            return
        }
        hasChosenInitialDay = true
        let startOfToday = Calendar.current.startOfDay(for: .now)
        if let nextEvent = events.first(where: { return $0.startAt >= startOfToday }) {
            selectedDay = nextEvent.day
        }
    }
}
