import SwiftUI

struct ProgressHeroCard: View {
    private static let minHeight: CGFloat = 140
    private static let mascotSize: CGFloat = 96
    private static let barHeight: CGFloat = 8
    private static let trackOpacity: Double = 0.22
    private static let captionOpacity: Double = 0.8
    private static let bubbleMaxWidth: CGFloat = 132
    private static let bubbleMinimumScale: CGFloat = 0.8
    private static let pointsMinimumScale: CGFloat = 0.5

    let points: Int
    var level: Level?
    var streakDays = 0
    var onTap: (() -> Void)?

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                card
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(.streakOpenHint))
        } else {
            card
        }
    }

    private var card: some View {
        return HStack(alignment: .center, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xSmall) {
                        levelCaption
                        streakBadge
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        levelCaption
                        streakBadge
                    }
                }
                Label {
                    Text(.pointsCount(points))
                        .contentTransition(.numericText(value: Double(points)))
                } icon: {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Palette.lime)
                }
                .font(.title.bold())
                .foregroundStyle(Palette.onForest)
                .lineLimit(1)
                .minimumScaleFactor(Self.pointsMinimumScale)
                if let level {
                    progressBar(level: level)
                        .padding(.top, Spacing.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: Spacing.xxSmall) {
                if let level {
                    Text(.xpLeftToLevel(level.xpLeft, level.number + 1))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(Self.bubbleMinimumScale)
                        .padding(.horizontal, Spacing.xSmall)
                        .padding(.vertical, Spacing.xxSmall)
                        .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.small))
                        .frame(maxWidth: Self.bubbleMaxWidth)
                }
                MascotImage(size: Self.mascotSize)
            }
        }
        .padding(Spacing.medium)
        .padding(.leading, Spacing.xSmall)
        .frame(maxWidth: .infinity, minHeight: Self.minHeight)
        .background(Palette.forest.gradient, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var levelCaption: some View {
        return Text(level.map { return .level($0.number) } ?? .yourBalance)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Palette.onForest.opacity(Self.captionOpacity))
            .lineLimit(1)
            .fixedSize()
    }

    @ViewBuilder
    private var streakBadge: some View {
        if streakDays > 0 {
            Label {
                Text(streakDays, format: .number)
            } icon: {
                Image(systemName: "flame.fill")
            }
            .accessibilityLabel(Text(.streakDays(streakDays)))
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.onLime)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, Spacing.hairline)
            .background(Palette.lime, in: .capsule)
        }
    }

    private func progressBar(level: Level) -> some View {
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.onForest.opacity(Self.trackOpacity))
                Capsule()
                    .fill(Palette.lime)
                    .frame(width: proxy.size.width * level.progress)
            }
        }
        .frame(height: Self.barHeight)
    }
}

#Preview {
    VStack {
        ProgressHeroCard(points: 500, level: Level(lifetimeXp: 2800), streakDays: 5)
        ProgressHeroCard(points: 12500, level: Level(lifetimeXp: 98000), streakDays: 125)
        ProgressHeroCard(points: 1_250_000, level: Level(lifetimeXp: 980_000), streakDays: 365)
        ProgressHeroCard(points: 120)
    }
    .padding()
}
