import SwiftUI

struct HomeScreen: View {
    private static let headerAvatarSize: CGFloat = 44
    private static let quickActionTileSize: CGFloat = 56
    private static let quickActionSymbolScale: CGFloat = 0.4
    private static let taskMascotSize: CGFloat = 34
    private static let placeholderTaskCount = 3
    private static let labelMinimumScale: CGFloat = 0.8
    private static let quickActionLineLimit = 2

    let uiState: HomeUiState
    let onProfile: () -> Void
    let onStreak: () -> Void
    let onQuickAction: (HomeQuickAction) -> Void
    let onEvent: (EcoEvent) -> Void
    let onTask: (EcoTask) -> Void
    let onAllTasks: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                header
                ProgressHeroCard(points: uiState.points, level: uiState.level, streakDays: uiState.streakDays, onTap: onStreak)
                    .redacted(reason: uiState.isLoading ? .placeholder : [])
                quickActions
                if let event = uiState.upcomingEvent {
                    Button {
                        onEvent(event)
                    } label: {
                        HeroImageCard(imageUrl: event.imageUrl, title: event.title, subtitle: event.scheduleSummary)
                    }
                    .buttonStyle(.plain)
                }
                SectionTitle(title: .yourTasks, actionTitle: .all, action: onAllTasks)
                tasksSection
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.large)
            .animation(.snappy, value: uiState.isLoading)
        }
        .background(Palette.screenBackground)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.secondaryText)
                Text(greeting)
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(Self.labelMinimumScale)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onProfile) {
                ProfileAvatar(style: uiState.avatar, size: Self.headerAvatarSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.profile))
        }
        .padding(.top, Spacing.xSmall)
        .accessibilityElement(children: .contain)
    }

    private var greeting: String {
        guard let displayName = uiState.displayName else {
            return String(localized: .hello)
        }
        return String(localized: .helloName(displayName))
    }

    private var quickActions: some View {
        HStack(alignment: .top) {
            ForEach(HomeQuickAction.allCases, id: \.self) { action in
                Button {
                    onQuickAction(action)
                } label: {
                    VStack(spacing: Spacing.xSmall) {
                        SymbolTile(systemImage: action.systemImage, size: Self.quickActionTileSize, symbolScale: Self.quickActionSymbolScale)
                        Text(action.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(Self.quickActionLineLimit)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var tasksSection: some View {
        if uiState.isLoading {
            TaskRowsCard(tasks: EcoTask.placeholders(count: Self.placeholderTaskCount), onTask: { _ in })
                .redacted(reason: .placeholder)
        } else if uiState.hasTasksError {
            StateView(kind: .error(retry: onRetry))
        } else if uiState.tasks.isEmpty {
            StateView(kind: .empty(message: .allTasksCompleted))
        } else {
            TaskRowsCard(tasks: uiState.tasks, onTask: onTask)
        }
    }
}

#Preview {
    NavigationStack {
        HomeScreen(
            uiState: HomeUiState(
                isLoading: false,
                displayName: "Роман",
                points: 420,
                level: Level(lifetimeXp: 2400),
                tasks: EcoTask.placeholders(count: 3)
            ),
            onProfile: {},
            onStreak: {},
            onQuickAction: { _ in },
            onEvent: { _ in },
            onTask: { _ in },
            onAllTasks: {},
            onRetry: {}
        )
    }
}
