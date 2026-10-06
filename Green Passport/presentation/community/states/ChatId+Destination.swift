extension ChatId {
    var destination: AppDestination {
        switch self {
        case .forum:
            return .forum
        case .group(let id):
            return .group(id: id)
        }
    }
}
