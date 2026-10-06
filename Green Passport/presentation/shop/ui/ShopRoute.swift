import SwiftUI

struct ShopRoute: View {
    let container: AppDIContainer

    @Environment(TabRouter.self) private var router
    @State private var viewModel: ShopViewModel
    @State private var pendingReward: Reward?

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildShopViewModel())
    }

    var body: some View {
        ShopScreen(
            uiState: viewModel.uiState,
            pendingReward: pendingReward,
            onPurchase: { reward in
                if viewModel.canAfford(reward) {
                    pendingReward = reward
                }
            },
            onConfirmPurchase: viewModel.purchase,
            onCancelPurchase: { pendingReward = nil },
            onCoupons: { router.push(.coupons) },
            onRetry: viewModel.retry
        )
        .task {
            await viewModel.observe()
        }
        .sensoryFeedback(.success, trigger: viewModel.purchaseCount)
        .couponDetailSheet(item: $viewModel.purchasedCoupon, container: container)
    }
}
