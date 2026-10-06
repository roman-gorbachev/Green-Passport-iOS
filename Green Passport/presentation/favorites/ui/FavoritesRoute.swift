import SwiftUI

struct FavoritesRoute: View {
    let container: AppDIContainer

    @Environment(AppRouter.self) private var router
    @State private var viewModel: FavoritesViewModel
    @State private var segment = FavoritesSegment.tasks
    @State private var selectedTask: TaskSheetItem?
    @State private var selectedPlaceId: String?

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildFavoritesViewModel())
    }

    var body: some View {
        FavoritesScreen(
            uiState: viewModel.uiState,
            segment: $segment,
            onAction: handle
        )
        .task {
            await viewModel.observe()
        }
        .onAppear {
            viewModel.refreshSavedPlaces()
        }
        .taskDetailSheet(item: $selectedTask, container: container)
        .sheet(item: selectedPlace) { point in
            MapPointSheet(
                point: point,
                isSaved: viewModel.uiState.savedMapPointIds.contains(point.id),
                onToggleSaved: { viewModel.toggleSavedPlace(point) },
                onRoute: { point.openDirections() }
            )
            .mapPointSheetPresentation()
        }
    }

    private var selectedPlace: Binding<MapPoint?> {
        return Binding(
            get: { return viewModel.uiState.mapPoints.first { return $0.id == selectedPlaceId } },
            set: { selectedPlaceId = $0?.id }
        )
    }

    private func handle(_ action: FavoritesUserAction) {
        switch action {
        case .taskSelected(let task):
            selectedTask = TaskSheetItem(id: task.id)
        case .tipSelected(let tip):
            router.push(.ecoTipDetail(tipId: tip.id))
        case .placeSelected(let point):
            selectedPlaceId = point.id
        case .taskRemoved(let task):
            viewModel.removeTask(task)
        case .tipRemoved(let tip):
            viewModel.removeTip(tip)
        case .placeRemoved(let point):
            viewModel.toggleSavedPlace(point)
        case .retry:
            viewModel.retry()
        }
    }
}
