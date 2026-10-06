struct ForumUiState {
    var posts: [ForumPost] = []
    var draft = ""
    var isLoading = true
    var hasError = false
    var isPosting = false
    var isTextRejected = false
    var isSendFailed = false
    var currentUserId: String?
    var reportedPostIds: Set<String> = []
    var composerMode = ComposerMode.new
}
