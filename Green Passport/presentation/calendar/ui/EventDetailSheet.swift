import SwiftUI

extension View {
    func eventDetailSheet(
        item: Binding<EventSheetItem?>,
        container: AppDIContainer,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        return sheet(item: item, onDismiss: onDismiss) { selected in
            EventDetailRoute(eventId: selected.id, container: container)
        }
    }
}
