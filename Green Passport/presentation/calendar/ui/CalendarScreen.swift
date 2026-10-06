import SwiftUI

struct CalendarScreen: View {
    private static let cardHeight: CGFloat = 160
    private static let dayTitleAnchorId = "dayTitle"
    private static let legendDotSize: CGFloat = 8

    let uiState: ListUiState<EcoEvent>
    let registeredEventIds: Set<String>
    let selectedDay: DateComponents
    let onSelectDay: (DateComponents) -> Void
    let onEvent: (EcoEvent) -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch uiState {
            case .loading:
                StateView(kind: .loading)
            case .error:
                StateView(kind: .error(retry: onRetry))
            case .success(let events) where events.isEmpty:
                StateView(kind: .empty(message: .calendarEmpty))
            case .success(let events):
                content(events: events)
            }
        }
        .background(Palette.screenBackground)
        .navigationTitle(Text(.calendar))
    }

    private var legend: some View {
        return HStack(spacing: Spacing.medium) {
            legendItem(title: .notRegistered, color: Palette.error)
            legendItem(title: .registered, color: Palette.forest)
        }
        .font(.footnote)
        .foregroundStyle(Palette.secondaryText)
        .frame(maxWidth: .infinity)
    }

    private func legendItem(title: LocalizedStringResource, color: Color) -> some View {
        return HStack(spacing: Spacing.xxSmall) {
            Circle()
                .fill(color)
                .frame(width: Self.legendDotSize, height: Self.legendDotSize)
            Text(title)
        }
    }

    private func content(events: [EcoEvent]) -> some View {
        let dayEvents = events.filter { return $0.day == selectedDay }
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    VStack(spacing: Spacing.xSmall) {
                        EventCalendarView(
                            dayCounts: DayEventCounts.byDay(events: events, registeredIds: registeredEventIds),
                            selectedDay: selectedDay,
                            onSelectDay: onSelectDay
                        )
                        legend
                    }
                    .padding(Spacing.small)
                    .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
                    if let date = selectedDay.startDate {
                        Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                            .font(.title3.bold())
                            .id(Self.dayTitleAnchorId)
                    }
                    if dayEvents.isEmpty {
                        Text(.calendarNoEventsOnDay)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                    } else {
                        LazyVStack(spacing: Spacing.small) {
                            ForEach(dayEvents) { event in
                                Button {
                                    onEvent(event)
                                } label: {
                                    HeroImageCard(
                                        imageUrl: event.imageUrl,
                                        title: event.title,
                                        subtitle: String(localized: .dateTime(event.dateText, event.timeText)),
                                        height: Self.cardHeight
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.large)
                .animation(.default, value: selectedDay)
            }
            .onChange(of: selectedDay) {
                withAnimation {
                    proxy.scrollTo(Self.dayTitleAnchorId, anchor: .top)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CalendarScreen(
            uiState: .success(data: [
                EcoEvent(id: "1", title: "Субботник в парке", description: "", location: "Парк Горького", city: "Минск", startAt: .now, imageUrl: nil, rewardPoints: 50),
            ]),
            registeredEventIds: ["1"],
            selectedDay: DateComponents.day(containing: .now),
            onSelectDay: { _ in },
            onEvent: { _ in },
            onRetry: {}
        )
    }
}
