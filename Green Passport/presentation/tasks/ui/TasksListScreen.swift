import SwiftUI

struct TasksListScreen: View {
    private static let mascotSize: CGFloat = 34

    let uiState: TasksListUiState
    let onAction: (TasksListUserAction) -> Void

    @State private var isFiltersPresented = false

    var body: some View {
        List {
            Group {
                content
            }
            .themedRowBackground()
        }
        .listStyle(.insetGrouped)
        .themedListBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            if !uiState.filterChips.isEmpty {
                activeFilters
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFiltersPresented = true
                } label: {
                    Image(systemName: uiState.filters.activeCount > 0
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                }
                .badge(uiState.filters.activeCount)
                .accessibilityLabel(Text(.filters))
            }
        }
        .sheet(isPresented: $isFiltersPresented) {
            TaskFiltersSheet(
                initialFilters: uiState.filters,
                profileCity: uiState.profile?.city,
                resultCount: { return uiState.tasks(for: $0).count },
                onApply: { onAction(.filtersChanged($0)) }
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(Palette.screenBackground)
            .presentationDragIndicator(.visible)
        }
        .overlay {
            overlayState
        }
        .navigationTitle(Text(.homeTileTasks))
        .animation(.snappy, value: uiState.filters)
    }

    @ViewBuilder
    private var content: some View {
        if !uiState.isLoading && !uiState.hasError && !uiState.visibleTasks.isEmpty {
            Section {
                ForEach(uiState.visibleTasks) { task in
                    row(for: task)
                }
            }
        }
    }

    private var activeFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xSmall) {
                ForEach(uiState.filterChips) { chip in
                    Button {
                        onAction(.filtersChanged(chip.remaining))
                    } label: {
                        HStack(spacing: Spacing.xxSmall) {
                            Text(chip.title)
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.forest)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xSmall)
                        .background(Palette.mintSurfaceHigh, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text(.removeFilter))
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xSmall)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var overlayState: some View {
        if uiState.isLoading {
            StateView(kind: .loading)
        } else if uiState.hasError {
            StateView(kind: .error(retry: { onAction(.retry) }))
        } else if uiState.visibleTasks.isEmpty {
            StateView(kind: .empty(message: .tasksEmpty))
        }
    }

    private func row(for task: EcoTask) -> some View {
        let isCompleted = uiState.completedTaskIds.contains(task.id)
        let isFavorite = uiState.favoriteTaskIds.contains(task.id)
        return Button {
            onAction(.taskSelected(task))
        } label: {
            ListRow(title: task.title, subtitle: subtitle(for: task, isCompleted: isCompleted)) {
                MascotImage(size: Self.mascotSize)
            } trailing: {
                if !isCompleted {
                    PointsBadge(points: task.rewardPoints)
                }
                FavoriteButton(isFavorite: isFavorite) {
                    onAction(.favoriteToggled(task))
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button {
                onAction(.favoriteToggled(task))
            } label: {
                Image(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
            }
            .tint(Palette.forest)
        }
    }

    private func subtitle(for task: EcoTask, isCompleted: Bool) -> String? {
        if isCompleted {
            return String(localized: .taskDetailCompletedLabel)
        }
        if uiState.pendingTaskIds.contains(task.id) {
            return String(localized: .underReview)
        }
        return String(localized: task.category.title)
    }
}

#Preview {
    NavigationStack {
        TasksListScreen(
            uiState: TasksListUiState(tasks: EcoTask.placeholders(count: 4), isLoading: false),
            onAction: { _ in }
        )
    }
}
