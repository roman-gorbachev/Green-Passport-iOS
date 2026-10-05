import SwiftUI

struct GameWebScreen: View {
    private static let bannerVisibleDuration = Duration.seconds(2)

    let title: String
    let url: URL?
    let uiState: GameWebUiState
    let reloadId: Int
    let onMessage: (GameBridgeMessage) -> Void
    let onLoadingChange: (Bool) -> Void
    let onFailure: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    @State private var isBannerVisible = false

    var body: some View {
        ZStack {
            Palette.screenBackground
                .ignoresSafeArea()
            if let url, !uiState.hasError {
                GameWebView(url: url, onMessage: onMessage, onLoadingChange: onLoadingChange, onFailure: onFailure)
                    .id(reloadId)
            }
            if uiState.hasError || url == nil {
                StateView(kind: .error(retry: onRetry))
            } else if uiState.isLoading {
                ProgressView()
            }
        }
        .overlay(alignment: .top) {
            if isBannerVisible {
                banner
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.xSmall)
                    .adaptiveGlassEffect(in: .capsule)
                    .padding(.top, Spacing.xSmall)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: isBannerVisible)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButton(action: onClose)
            }
        }
        .sensoryFeedback(uiState.rewardFailure == nil ? .success : .error, trigger: uiState.rewardCount)
        .task(id: uiState.rewardCount) {
            guard uiState.rewardCount > 0 else {
                return
            }
            isBannerVisible = true
            try? await Task.sleep(for: Self.bannerVisibleDuration)
            isBannerVisible = false
        }
    }

    @ViewBuilder
    private var banner: some View {
        if let failure = uiState.rewardFailure {
            Text(failure.message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.error)
        } else if let reward = uiState.lastReward {
            HStack(spacing: Spacing.xSmall) {
                PointsBadge(points: reward.points)
                if reward.streakBonus > 0 {
                    Text(.streakBonusMsg(reward.streakBonus))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                }
            }
        }
    }
}
