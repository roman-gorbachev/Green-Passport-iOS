import Foundation

struct CommunityHubUiState {
    var forum = ChatSummary(chatId: .forum, groupName: nil, lastMessageAt: nil, settings: .defaults(for: .forum))
    var groups: [ChatSummary] = []
    var archivedCount = 0
    var query = ""
    var myGroupMatches: [GroupSearchResult] = []
    var otherGroupMatches: [GroupSearchResult] = []
    var currentUserId: String?
    var isLoading = true
    var hasError = false
    var groupDraftName = ""
    var isCreatingGroup = false
    var isGroupNameRejected = false
    var inviteCodeDraft = ""
    var isJoiningByCode = false
    var isInviteCodeNotFound = false

    var isSearching: Bool {
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
