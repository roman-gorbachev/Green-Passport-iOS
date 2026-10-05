import Foundation

struct DayEventCounts: Hashable {
    let open: Int
    let registered: Int

    static func byDay(events: [EcoEvent], registeredIds: Set<String>) -> [DateComponents: DayEventCounts] {
        return Dictionary(grouping: events, by: \.day).mapValues { dayEvents in
            let registered = dayEvents.filter { return registeredIds.contains($0.id) }.count
            return DayEventCounts(open: dayEvents.count - registered, registered: registered)
        }
    }
}
