struct GroupDetailUiState {
    var group: CommunityGroup?
    var messages: [GroupMessage] = []
    var members: [GroupMember] = []
    var draft = ""
    var currentUserId: String?
    var isLoading = true
    var hasError = false
    var isLoadingMessages = true
    var hasMessagesError = false
    var isLoadingMembers = false
    var isSending = false
    var isTextRejected = false
    var isSendFailed = false
    var isJoining = false
    var isLeaving = false
    var composerMode = ComposerMode.new

    var isMember: Bool {
        guard let group, let currentUserId else {
            return false
        }
        return group.memberIds.contains(currentUserId)
    }
}
