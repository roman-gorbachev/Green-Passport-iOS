import Foundation

nonisolated struct GroupSearchResult: Identifiable, Hashable, Sendable {
    let group: CommunityGroup
    let matchedMemberName: String?

    var id: String {
        return group.id
    }
}
