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
                        onRoute: { point.openDirections() }
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
}
