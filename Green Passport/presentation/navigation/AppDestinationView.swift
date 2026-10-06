import SwiftUI

struct AppDestinationView: View {
    let destination: AppDestination
    let container: AppDIContainer

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        switch destination {
        case .tasks:
            TasksListRoute(container: container)
        case .profile:
            ProfileRoute(container: container)
        case .achievements:
            AchievementsRoute(container: container)
        case .history:
            HistoryRoute(container: container)
        case .calendar:
            CalendarRoute(container: container)
        case .community:
            CommunityHubRoute(container: container)
        case .forum:
            ForumRoute(container: container)
        case .groups:
            GroupsRoute(container: container)
        case .archivedChats:
            ArchivedChatsRoute(container: container)
        case .group(let id):
            GroupDetailRoute(groupId: id, container: container)
        case .ecoTips:
            EcoTipsListRoute(container: container)
        case .ecoTipDetail(let tipId):
            EcoTipDetailRoute(tipId: tipId, container: container)
        case .feedback:
            FeedbackRoute(container: container)
        case .games:
            GamesHubRoute(container: container)
        case .moderation:
            ModerationRoute(container: container)
        case .notifications:
            NotificationsRoute(container: container)
        case .coupons:
            CouponsRoute(container: container)
        }
    }
}
