import Foundation

nonisolated struct CommunityGroup: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let memberIds: [String]
    var ownerId: String?
    var inviteCode: String?
    var lastMessageAt: Date?
}
