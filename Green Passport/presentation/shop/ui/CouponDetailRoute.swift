import SwiftUI

struct CouponDetailRoute: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CouponDetailViewModel

    init(item: CouponItem, container: AppDIContainer) {
        _viewModel = State(initialValue: container.buildCouponDetailViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            CouponDetailScreen(uiState: viewModel.uiState, onMarkUsed: viewModel.markUsed)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
        }
        .task {
            await viewModel.observe()
        }
    }
}
