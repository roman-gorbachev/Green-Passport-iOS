import SwiftUI
import UIKit

struct EventCalendarView: UIViewRepresentable {
    let dayCounts: [DateComponents: DayEventCounts]
    let selectedDay: DateComponents
    let onSelectDay: (DateComponents) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.tintColor = UIColor(Palette.forest)
        calendarView.delegate = context.coordinator
        calendarView.visibleDateComponents = selectedDay
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selection.selectedDate = selectedDay
        calendarView.selectionBehavior = selection
        return calendarView
    }

    func updateUIView(_ calendarView: UICalendarView, context: Context) {
        let previousCounts = context.coordinator.dayCounts
        context.coordinator.parent = self
        context.coordinator.dayCounts = dayCounts
        let changedDays = Set(previousCounts.keys).union(dayCounts.keys).filter { day in
            return previousCounts[day] != dayCounts[day]
        }
        let reloadedDays = changedDays.compactMap { day in
            return day.startDate.map { date in
                return calendarView.calendar.dateComponents([.calendar, .era, .year, .month, .day], from: date)
            }
        }
        if !reloadedDays.isEmpty {
            calendarView.reloadDecorations(forDateComponents: reloadedDays, animated: true)
        }
        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate,
           selection.selectedDate?.dayOnly != selectedDay {
            selection.setSelected(selectedDay, animated: true)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        guard let width = proposal.width else {
            return nil
        }
        let height = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return CGSize(width: width, height: height)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: EventCalendarView
        var dayCounts: [DateComponents: DayEventCounts]

        init(parent: EventCalendarView) {
            self.parent = parent
            self.dayCounts = parent.dayCounts
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let counts = dayCounts[dateComponents.dayOnly] else {
                return nil
            }
            return .customView {
                return EventCountBadge.make(counts: counts)
            }
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents else {
                return
            }
            parent.onSelectDay(dateComponents.dayOnly)
        }
    }
}
