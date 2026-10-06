import SwiftUI

struct CouponDetailScreen: View {
    private static let qrSize: CGFloat = 200
    private static let qrPadding: CGFloat = 12
    private static let codeTracking: CGFloat = 4
    private static let secondaryOnForestOpacity: Double = 0.8
    private static let cardGradientEndOpacity: Double = 0.7

    let uiState: CouponDetailUiState
    let onMarkUsed: () -> Void

    @State private var isConfirmationPresented = false

    var body: some View {
        let item = uiState.item
        let now = Date()
        let status = item.coupon.status(at: now)
        ScrollView {
            VStack(spacing: Spacing.large) {
                VStack(spacing: Spacing.xSmall) {
                    if let partner = item.reward?.partnerName {
                        Text(partner)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.secondaryText)
                    }
                    Text(item.title)
                        .font(.title2.bold())
                    Text(item.statusText(at: now))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.isExpiringSoon(at: now) || status == .expired ? Palette.error : Palette.forest)
                }
                .multilineTextAlignment(.center)
                if let code = item.coupon.code {
                    VStack(spacing: Spacing.medium) {
                        QrCodeImage(payload: uiState.qrPayload ?? code)
                            .frame(width: Self.qrSize, height: Self.qrSize)
                            .padding(Self.qrPadding)
                            .background(.white, in: .rect(cornerRadius: CornerRadius.medium, style: .continuous))
                        VStack(spacing: Spacing.xxSmall) {
                            Text(.couponCode)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Palette.onForest.opacity(Self.secondaryOnForestOpacity))
                            Text(code)
                                .font(.title.monospaced().bold())
                                .tracking(Self.codeTracking)
                                .foregroundStyle(Palette.onForest)
                                .textSelection(.enabled)
                        }
                        Text(.partnerScansQrMsg)
                            .font(.footnote)
                            .foregroundStyle(Palette.onForest.opacity(Self.secondaryOnForestOpacity))
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.large)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Palette.forestDeep, Palette.forestDeep.opacity(Self.cardGradientEndOpacity)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                    .opacity(status == .active ? 1 : Palette.disabledOpacity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.screenHorizontal)
        }
        .background(Palette.screenBackground)
        .safeAreaInset(edge: .bottom) {
            if status == .active && item.coupon.code != nil {
                VStack(spacing: Spacing.small) {
                    if let failure = uiState.failure {
                        Text(failure.couponMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.error)
                    }
                    AppButton(title: .markAsUsed, isLoading: uiState.isMarking) {
                        isConfirmationPresented = true
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.medium)
            }
        }
        .confirmationDialog(Text(.markAsUsed), isPresented: $isConfirmationPresented, titleVisibility: .visible) {
            Button(action: onMarkUsed) {
                Text(.markAsUsed)
            }
        } message: {
            Text(.markCouponUsedMsg)
        }
        .sensoryFeedback(.success, trigger: status == .used)
    }
}

#Preview {
    CouponDetailScreen(
        uiState: CouponDetailUiState(item: CouponItem(
            coupon: Coupon(id: "1", rewardId: "r", code: "GP7K2MXQ", redeemedAt: .now, expiresAt: .now.addingTimeInterval(200_000), usedAt: nil),
            reward: Reward(id: "r", title: "Скидка 10% на кофе", partnerName: "Кофейня «Зелёный лист»", pointsCost: 100)
        )),
        onMarkUsed: {}
    )
}
