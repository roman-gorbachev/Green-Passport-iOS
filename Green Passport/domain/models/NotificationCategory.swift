import Foundation

nonisolated enum NotificationCategory: String, CaseIterable, Hashable, Sendable {
    case events
    case tasks
    case messages
}
