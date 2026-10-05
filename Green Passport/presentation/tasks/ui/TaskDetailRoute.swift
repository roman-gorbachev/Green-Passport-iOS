import PhotosUI
import SwiftUI

struct TaskDetailRoute: View {
    @State private var viewModel: TaskDetailViewModel
    @State private var isPhotoSourcePresented = false
    @State private var isLibraryPresented = false
    @State private var isCameraPresented = false
    @State private var isScannerPresented = false
    @State private var libraryItem: PhotosPickerItem?

    init(taskId: String, container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildTaskDetailViewModel(taskId: taskId))
    }

    var body: some View {
        TaskDetailScreen(
            uiState: viewModel.uiState,
            onConfirm: confirm,
            onToggleFavorite: viewModel.toggleFavorite,
            onRetry: viewModel.retry
        )
        .fittedSheetDetent()
        .task {
            await viewModel.observe()
        }
        .confirmationDialog(Text(.attachPhoto), isPresented: $isPhotoSourcePresented, titleVisibility: .hidden) {
            if CameraPicker.isAvailable {
                Button {
                    isCameraPresented = true
                } label: {
                    Text(.takePhoto)
                }
            }
            Button {
                isLibraryPresented = true
            } label: {
                Text(.chooseFromLibrary)
            }
        }
        .photosPicker(isPresented: $isLibraryPresented, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) { _, item in
            guard let item else {
                return
            }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    viewModel.submitPhoto(data)
                }
                libraryItem = nil
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker(onImage: viewModel.submitPhoto)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isScannerPresented) {
            QrScannerScreen(
                onCode: { code in
                    isScannerPresented = false
                    viewModel.redeemCode(code)
                },
                onClose: { isScannerPresented = false }
            )
        }
    }

    private func confirm() {
        guard let task = viewModel.uiState.task else {
            return
        }
        switch task.verification {
        case .selfReported:
            viewModel.completeTask()
        case .qr:
            isScannerPresented = true
        case .photo:
            isPhotoSourcePresented = true
        }
    }
}
