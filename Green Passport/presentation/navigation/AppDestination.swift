enum AppDestination: Hashable {
    case tasks
    case profile
    case achievements
    case history
    case community
    case games
    case ecoTips
    case calendar
    case feedback
    case ecoTipDetail(tipId: String)
    case forum
    case archivedChats
    case group(id: String)
    case moderation
    case notifications
    case coupons
}
