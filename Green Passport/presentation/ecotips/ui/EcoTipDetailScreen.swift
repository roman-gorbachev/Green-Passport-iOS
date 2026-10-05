import SwiftUI

struct EcoTipDetailScreen: View {
    private static let coverHeight: CGFloat = 220
    private static let metaSeparator = " · "

    let uiState: EcoTipDetailUiState
    let onMarkRead: () -> Void
    let onToggleBookmark: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
            } else if let tip = uiState.tip, !uiState.isLoading {
                content(tip: tip)
            } else {
                StateView(kind: .loading)
            }
        }
        .background(Palette.screenBackground)
        .navigationTitle(Text(.ecotipDetailTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if uiState.tip != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    FavoriteButton(isFavorite: uiState.isBookmarked, action: onToggleBookmark)
                }
            }
        }
        .sensoryFeedback(.success, trigger: uiState.isRead) { _, isRead in
            return isRead
        }
    }

    @ViewBuilder
    private func media(url: URL, mediaUrl: String, isVideo: Bool) -> some View {
        if isVideo {
            Link(destination: url) {
                Label {
                    Text(.watchVideo)
                } icon: {
                    Image(systemName: "play.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .adaptiveGlassButtonStyle()
            .controlSize(.large)
        } else {
            Link(destination: url) {
                Label {
                    Text(mediaUrl)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "link")
                }
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private func content(tip: EcoTip) -> some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                ArticleCoverImage(tip: tip)
                    .frame(height: Self.coverHeight)
                    .clipShape(.rect(cornerRadius: CornerRadius.large, style: .continuous))
                Label {
                    Text([String(localized: tip.category.title), String(localized: .ecotipReadMinutesFormat(tip.readMinutes))].joined(separator: Self.metaSeparator))
                } icon: {
                    Image(systemName: tip.category.systemImage)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.forest)
                Text(tip.title)
                    .font(.largeTitle.bold())
                MarkdownArticleView(markdown: tip.body)
                if let mediaUrl = tip.mediaUrl, let url = URL(string: mediaUrl) {
                    media(url: url, mediaUrl: mediaUrl, isVideo: tip.category == .video)
                }
                Text(.ecotipDetailRewardFormat(tip.rewardPoints, tip.rewardXp))
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.large)
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if uiState.isRead {
                    VStack(spacing: Spacing.xxSmall) {
                        Label {
                            Text(.ecotipDetailReadLabel)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.headline)
                        .foregroundStyle(Palette.forest)
                        if uiState.streakBonus > 0 {
                            Text(.streakBonusMsg(uiState.streakBonus))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.forest)
                        }
                    }
                } else {
                    VStack(spacing: Spacing.small) {
                        if let failure = uiState.failure {
                            Text(failure.message)
                                .font(.footnote)
                                .foregroundStyle(Palette.error)
                        }
                        AppButton(title: .ecotipDetailMarkReadButton, isLoading: uiState.isSubmitting, action: onMarkRead)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.medium)
        }
    }
}

#Preview {
    NavigationStack {
        EcoTipDetailScreen(
            uiState: EcoTipDetailUiState(
                tip: EcoTip(id: "1", category: .video, title: "Как сортировать пластик", body: "Смотрите на маркировку на упаковке.\n\n## Что означают цифры\n\n- **1 PET** — бутылки\n- **2 HDPE** — канистры", mediaUrl: "https://example.com", isDailyTip: false, rewardPoints: 10, rewardXp: 20),
                isLoading: false
            ),
            onMarkRead: {},
            onToggleBookmark: {},
            onRetry: {}
        )
    }
}
