import Foundation

nonisolated enum ChatId: Hashable, Sendable {
    case forum
    case group(id: String)

    private static let forumRawValue = "forum"

    var rawValue: String {
        switch self {
        case .forum:
            return Self.forumRawValue
        case .group(let id):
            return id
        }
    }

    init(rawValue: String) {
        self = rawValue == Self.forumRawValue ? .forum : .group(id: rawValue)
    }
}
