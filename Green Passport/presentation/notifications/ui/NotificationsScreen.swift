import SwiftUI

struct NotificationsScreen: View {
    let entries: [NotificationLogEntry]?

    var body: some View {
        List(entries ?? []) { entry in
            Group {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(entry.sentAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.forest)
                    Text(entry.title)
                        .font(.headline)
                    Text(entry.body)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .padding(.vertical, Spacing.xxSmall)
            }
            .themedRowBackground()
        }
        .listStyle(.insetGrouped)
        .themedListBackground()
        .overlay {
            if entries?.isEmpty == true {
                StateView(kind: .empty(message: .notificationsEmpty))
            }
        }
        .navigationTitle(Text(.notificationsScreenTitle))
    }
}

#Preview {
    NavigationStack {
        NotificationsScreen(entries: [NotificationLogEntry(id: UUID(), title: "Задание выполнено", body: "+50 баллов, +50 опыта", sentAt: .now)])
    }
}
