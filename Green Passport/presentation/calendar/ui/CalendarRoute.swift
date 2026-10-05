import SwiftUI

struct CalendarRoute: View {
    let container: AppDIContainer

    @State private var viewModel: CalendarViewModel
    @State private var selectedEvent: EventSheetItem?

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildCalendarViewModel())
    }

    var body: some View {
        CalendarScreen(
            uiState: viewModel.uiState,
            registeredEventIds: viewModel.registeredEventIds,
            selectedDay: viewModel.selectedDay,
            onSelectDay: viewModel.selectDay,
            onEvent: { selectedEvent = EventSheetItem(id: $0.id) },
            onRetry: viewModel.retry
        )
        .task(id: viewModel.observationId) {
            await viewModel.observe()
        }
        .eventDetailSheet(item: $selectedEvent, container: container)
    }
}
