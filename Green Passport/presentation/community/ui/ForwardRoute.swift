import SwiftUI

struct ForwardRoute: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ForwardViewModel

    init(message: MessageTarget, container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildForwardViewModel(message: message))
    }

    var body: some View {
        NavigationStack {
            ForwardScreen(uiState: viewModel.uiState, onForward: viewModel.forward)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.screenBackground)
        .task {
            await viewModel.observe()
        }
        .sensoryFeedback(.success, trigger: viewModel.uiState.isSent)
        .onChange(of: viewModel.uiState.isSent) { _, isSent in
            if isSent {
                dismiss()
            }
        }
    }
}
