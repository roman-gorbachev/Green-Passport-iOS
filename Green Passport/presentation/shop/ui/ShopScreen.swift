import SwiftUI

struct ShopScreen: View {
    private static let rewardThumbnailSize: CGFloat = 56

    let uiState: ShopUiState
    let pendingReward: Reward?
    let onPurchase: (Reward) -> Void
    let onConfirmPurchase: (Reward) -> Void
    let onCancelPurchase: () -> Void
    let onCoupons: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            if uiState.isLoading {
                StateView(kind: .loading)
                    .containerRelativeFrame(.vertical)
            } else if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
                    .containerRelativeFrame(.vertical)
            } else {
                content
            }
        }
        .background(Palette.screenBackground)
        .navigationTitle(Text(.shop))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                ProgressHeroCard(points: uiState.points)
                if let purchaseFailure = uiState.purchaseFailure {
                    Text(purchaseFailure.purchaseMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.error)
                }
            }
            SectionTitle(title: .shopCatalogTitle)
            if uiState.rewards.isEmpty {
                emptyText(.shopEmptyRewards)
            } else {
                card {
                    ForEach(uiState.rewards) { reward in
                        rewardRow(reward)
                        if reward.id != uiState.rewards.last?.id {
                            Divider()
                        }
                    }
                }
            }
            Button(action: onCoupons) {
                ListRow(
                    title: String(localized: .myCoupons),
                    subtitle: String(localized: .activeCouponsCount(uiState.activeCouponCount))
                ) {
                    SymbolTile(systemImage: "ticket.fill")
                } trailing: {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.large)
    }

    private func rewardRow(_ reward: Reward) -> some View {
        return HStack(spacing: Spacing.small) {
            if let imageUrl = reward.imageUrl {
                RemoteImage(url: URL(string: imageUrl))
                    .frame(width: Self.rewardThumbnailSize, height: Self.rewardThumbnailSize)
                    .clipShape(.rect(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(reward.title)
                    .font(.headline)
                Text(reward.partnerName)
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Text(.shopCostFormat(reward.pointsCost))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.forest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onPurchase(reward)
            } label: {
                Text(.shopPurchaseButton)
                    .loadingOverlay(uiState.purchasingRewardId == reward.id, tint: Palette.onForest)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(uiState.purchasingRewardId != nil)
            .confirmationDialog(
                Text(.shopPurchaseButton),
                isPresented: Binding(
                    get: { return pendingReward?.id == reward.id },
                    set: { isPresented in
                        if !isPresented {
                            onCancelPurchase()
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button {
                    onConfirmPurchase(reward)
                } label: {
                    Text(.shopPurchaseButton)
                }
            } message: {
                Text(.exchangePointsForRewardMsg(reward.pointsCost, reward.title))
            }
        }
        .padding(.vertical, Spacing.small)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        return VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, Spacing.medium)
        .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
    }

    private func emptyText(_ text: LocalizedStringResource) -> some View {
        return Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.secondaryText)
    }
}

#Preview {
    NavigationStack {
        ShopScreen(
            uiState: ShopUiState(
                points: 320,
                rewards: [Reward(id: "1", title: "Скидка 10% на кофе", partnerName: "Green Coffee", pointsCost: 150)],
                isLoading: false
            ),
            pendingReward: nil,
            onPurchase: { _ in },
            onConfirmPurchase: { _ in },
            onCancelPurchase: {},
            onCoupons: {},
            onRetry: {}
        )
    }
}
