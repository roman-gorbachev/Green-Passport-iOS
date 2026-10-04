import MapKit
import SwiftUI

struct MapRoute: View {
    @State private var viewModel: MapViewModel
    @State private var selectedPointId: String?

    init(container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildMapViewModel())
    }

    var body: some View {
        MapScreen(
            uiState: viewModel.uiState,
            searchQuery: $viewModel.uiState.searchQuery,
            selectedPointId: $selectedPointId,
            onFilter: { viewModel.uiState.filter = $0 },
            onRetry: viewModel.retry
        )
        .task(id: viewModel.observationId) {
            await viewModel.observe()
        }
        .sheet(isPresented: isSheetPresented) {
            Group {
                if let point = selectedPoint {
                    MapPointSheet(
                        point: point,
                        isSaved: viewModel.uiState.savedPointIds.contains(point.id),
                        onToggleSaved: { viewModel.toggleSaved(point) },
                        onRoute: { openDirections(to: point) }
                    )
                }
            }
            .mapPointSheetPresentation()
        }
    }

    private var selectedPoint: MapPoint? {
        return viewModel.uiState.points.first { return $0.id == selectedPointId }
    }

    private var isSheetPresented: Binding<Bool> {
        return Binding(
            get: { return selectedPoint != nil },
            set: { isPresented in
                if !isPresented {
                    selectedPointId = nil
                }
            }
        )
    }

    private func openDirections(to point: MapPoint) {
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = point.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}
