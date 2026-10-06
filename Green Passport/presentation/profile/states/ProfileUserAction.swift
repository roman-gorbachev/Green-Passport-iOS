enum ProfileUserAction {
    case open(AppDestination)
    case editProfile
    case moderation
    case language
    case themeSelected(AppTheme)
    case notificationCategoryToggled(NotificationCategory, Bool)
    case signOut
    case retry
}
