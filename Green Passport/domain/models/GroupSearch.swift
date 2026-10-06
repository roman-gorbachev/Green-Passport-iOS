import Foundation

nonisolated enum GroupSearch {
    static func matches(_ groups: [CommunityGroup], query: String, memberNames: [String: String]) -> [GroupSearchResult] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else {
            return []
        }
        return groups.compactMap { group in
            if group.name.lowercased().contains(needle) {
                return GroupSearchResult(group: group, matchedMemberName: nil)
            }
            let member = group.memberIds
                .compactMap { return memberNames[$0] }
                .first { return $0.lowercased().contains(needle) }
            return member.map { return GroupSearchResult(group: group, matchedMemberName: $0) }
        }
    }
}
