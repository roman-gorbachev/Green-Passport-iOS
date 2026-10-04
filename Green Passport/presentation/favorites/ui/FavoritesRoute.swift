import MapKit
import SwiftUI

struct FavoritesRoute: View {
    let container: AppDIContainer

    @Environment(TabRouter.self) private var router
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
            onTask: { selectedTask = TaskSheetItem(id: $0.id) },
            onTip: { router.push(.ecoTipDetail(tipId: $0.id)) },
            onPlace: { selectedPlaceId = $0.id },
            onRetry: viewModel.retry
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
                onRoute: { openDirections(to: point) }
            )
            .mapPointSheetPresentation()
        }
    }

    private var selectedPlace: Binding<MapPoint?> {
        return Binding(
            get: { return viewModel.uiState.savedPlaces.first { return $0.id == selectedPlaceId } },
            set: { selectedPlaceId = $0?.id }
        )
    }

    private func openDirections(to point: MapPoint) {
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = point.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}
