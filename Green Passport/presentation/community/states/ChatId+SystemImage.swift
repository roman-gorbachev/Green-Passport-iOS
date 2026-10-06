extension ChatId {
    var systemImage: String {
        switch self {
        case .forum:
            return "bubble.left.and.bubble.right.fill"
        case .group:
            return "person.3.fill"
        }
    }
}
