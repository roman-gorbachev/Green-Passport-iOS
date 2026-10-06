struct ForwardUiState {
    var groups: [CommunityGroup] = []
    var isLoading = true
    var sendingChatId: ChatId?
    var isSendFailed = false
    var isTextRejected = false
    var isSent = false
}
