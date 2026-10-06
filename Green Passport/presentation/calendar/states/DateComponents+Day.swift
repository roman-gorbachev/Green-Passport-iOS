import Foundation

extension DateComponents {
    static func day(containing date: Date) -> DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day], from: date).dayOnly
    }

    var dayOnly: DateComponents {
        return DateComponents(year: year, month: month, day: day)
    }

    var startDate: Date? {
        return Calendar.current.date(from: dayOnly)
    }
}
