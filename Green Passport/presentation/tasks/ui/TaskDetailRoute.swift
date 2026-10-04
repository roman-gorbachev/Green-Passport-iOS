import PhotosUI
import SwiftUI
import UIKit

struct TaskDetailRoute: View {
    private static let minSheetHeight: CGFloat = 320
    private static let sheetChromeHeight: CGFloat = 80

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TaskDetailViewModel
    @State private var isPhotoSourcePresented = false
    @State private var isLibraryPresented = false
    @State private var isCameraPresented = false
    @State private var isScannerPresented = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var measuredContentHeight: CGFloat = 0

    init(taskId: String, container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildTaskDetailViewModel(taskId: taskId))
    }

    var body: some View {
        NavigationStack {
            TaskDetailScreen(
                uiState: viewModel.uiState,
                onConfirm: confirm,
                onRetry: viewModel.retry
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { measuredContentHeight = $0 }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
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

    private var sheetHeight: CGFloat {
        return max(measuredContentHeight + Self.sheetChromeHeight, Self.minSheetHeight)
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
