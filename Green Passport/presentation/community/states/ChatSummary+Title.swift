import Foundation

extension ChatSummary {
    var title: String {
        return groupName ?? String(localized: .communityForumTitle)
    }
}
