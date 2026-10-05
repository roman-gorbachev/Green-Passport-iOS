struct EcoTipDetailUiState {
    var tip: EcoTip?
    var isRead = false
    var isBookmarked = false
    var isLoading = true
    var isSubmitting = false
    var hasError = false
    var streakBonus = 0
    var failure: RewardFailure?
}
