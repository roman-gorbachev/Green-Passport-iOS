struct TaskDetailUiState {
    var task: EcoTask?
    var isCompleted = false
    var isFavorite = false
    var submission: TaskSubmission?
    var isLoading = true
    var isSubmitting = false
    var hasError = false
    var earnedPoints: Int?
    var streakBonus = 0
    var failure: RewardFailure?
}
