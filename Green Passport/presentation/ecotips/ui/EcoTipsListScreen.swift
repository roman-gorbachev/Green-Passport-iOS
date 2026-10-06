import SwiftUI

struct EcoTipsListScreen: View {
    private static let thumbnailSize: CGFloat = 64
    private static let previewLineLimit = 2
    private static let metaSeparator = " · "
    private static let rowInsets = EdgeInsets(
        top: 0,
        leading: Spacing.screenHorizontal,
        bottom: Spacing.small,
        trailing: Spacing.screenHorizontal
    )

    let uiState: EcoTipsListUiState
    let onFilter: (EcoTipFilter) -> Void
    let onTip: (EcoTip) -> Void
    let onToggleBookmark: (EcoTip) -> Void
    let onRetry: () -> Void

    var body: some View {
        List {
            Group {
                if let dailyTip = uiState.dailyTip {
                    dailyTipCard(dailyTip)
                        .listRowInsets(Self.rowInsets)
                }
                FilterBar(options: EcoTipFilter.allFilters, selected: uiState.filter, title: { return $0.title }, onSelect: onFilter)
                    .listRowInsets(EdgeInsets())
                content
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .themedListBackground()
        .navigationTitle(Text(.homeTileEcotips))
    }

    @ViewBuilder
    private var content: some View {
        if uiState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xLarge)
        } else if uiState.hasError {
            StateView(kind: .error(retry: onRetry))
        } else if uiState.visibleTips.isEmpty {
            StateView(kind: .empty(message: .ecotipsEmpty))
        } else {
            ForEach(uiState.visibleTips) { tip in
                row(tip)
                    .listRowInsets(Self.rowInsets)
            }
        }
    }

    private func dailyTipCard(_ tip: EcoTip) -> some View {
        return Button {
            onTip(tip)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Label {
                    Text(.ecotipsDailyTipLabel)
                } icon: {
                    Image(systemName: "sun.max.fill")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.forest)
                Text(tip.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text(tip.preview)
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.medium)
            .background(Palette.mintSurface, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func row(_ tip: EcoTip) -> some View {
        let isRead = uiState.readTipIds.contains(tip.id)
        let isBookmarked = uiState.bookmarkedTipIds.contains(tip.id)
        return Button {
            onTip(tip)
        } label: {
            HStack(alignment: .top, spacing: Spacing.small) {
                ArticleCoverImage(tip: tip)
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                    .clipShape(.rect(cornerRadius: CornerRadius.tile, style: .continuous))
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(Self.previewLineLimit)
                    Text(tip.preview)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(Self.previewLineLimit)
                    HStack(spacing: Spacing.xxSmall) {
                        if isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.forest)
                                .accessibilityLabel(Text(.ecotipDetailReadLabel))
                        }
                        Text([String(localized: tip.category.title), String(localized: .ecotipReadMinutesFormat(tip.readMinutes))].joined(separator: Self.metaSeparator))
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                FavoriteButton(isFavorite: isBookmarked) {
                    onToggleBookmark(tip)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button {
                onToggleBookmark(tip)
            } label: {
                Image(systemName: isBookmarked ? "heart.slash.fill" : "heart.fill")
            }
            .tint(Palette.forest)
        }
    }
}

#Preview {
    NavigationStack {
        EcoTipsListScreen(
            uiState: EcoTipsListUiState(
                tips: [EcoTip(id: "1", category: .article, title: "Как сортировать пластик", body: "Смотрите на маркировку на упаковке: цифра в треугольнике подскажет, куда нести пластик.\n\n## Что означают цифры", mediaUrl: nil, isDailyTip: true, rewardPoints: 10, rewardXp: 20)],
                isLoading: false
            ),
            onFilter: { _ in },
            onTip: { _ in },
            onToggleBookmark: { _ in },
            onRetry: {}
        )
    }
}
