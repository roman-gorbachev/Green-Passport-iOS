import SwiftUI

struct HomeRoute: View {
    private static let streakSheetEstimatedHeight: CGFloat = 360
    private static let streakSheetBottomAllowance: CGFloat = 24

    let container: AppDIContainer

    @Environment(AppRouter.self) private var router
    @State private var viewModel: HomeViewModel
    @State private var selectedTask: TaskSheetItem?
    @State private var selectedEvent: EventSheetItem?
    @State private var isStreakSheetPresented = false
    @State private var streakSheetHeight: CGFloat = HomeRoute.streakSheetEstimatedHeight

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildHomeViewModel())
    }

    var body: some View {
        HomeScreen(
            uiState: viewModel.uiState,
            onProfile: { router.push(.profile) },
            onStreak: { isStreakSheetPresented = true },
            onQuickAction: { router.push($0.destination) },
            onEvent: { selectedEvent = EventSheetItem(id: $0.id) },
            onTask: { selectedTask = TaskSheetItem(id: $0.id) },
            onAllTasks: { router.push(.tasks) },
            onRetry: viewModel.retry
        )
        .task {
            await viewModel.observe()
        }
        .taskDetailSheet(item: $selectedTask, container: container)
        .eventDetailSheet(item: $selectedEvent, container: container)
        .sheet(isPresented: $isStreakSheetPresented) {
            StreakSheet(summary: Streak.summary(of: viewModel.uiState.streak, at: Date()))
                .onGeometryChange(for: CGFloat.self) { proxy in
                    return proxy.size.height
                } action: { height in
                    guard height > 0 else {
                        return
                    }
                    streakSheetHeight = height + Self.streakSheetBottomAllowance
                }
                .presentationDetents([.height(streakSheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.cardBackground)
        }
    }
}
