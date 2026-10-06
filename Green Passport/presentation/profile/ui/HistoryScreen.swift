import SwiftUI

struct HistoryScreen: View {
    private static let tileSize: CGFloat = 36

    let uiState: ListUiState<HistoryEntry>
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch uiState {
            case .loading:
                StateView(kind: .loading)
            case .error:
                StateView(kind: .error(retry: onRetry))
            case .success(let entries) where entries.isEmpty:
                StateView(kind: .empty(message: .historyEmpty))
            case .success(let entries):
                List(entries) { entry in
                    Group {
                        ListRow(
                            title: entry.title,
                            subtitle: String(localized: .historyRowSubtitleFormat(
                                String(localized: entry.type.title),
                                entry.timestamp.formatted(date: .abbreviated, time: .shortened)
                            ))
                        ) {
                            SymbolTile(systemImage: entry.type.systemImage, size: Self.tileSize)
                        } trailing: {
                            EmptyView()
                        }
                    }
                    .themedRowBackground()
                }
                .listStyle(.insetGrouped)
                .themedListBackground()
            }
        }
        .background(Palette.screenBackground)
        .navigationTitle(Text(.historyScreenTitle))
    }
}

#Preview {
    NavigationStack {
        HistoryScreen(
            uiState: .success(data: [HistoryEntry(id: "1", type: .taskCompleted, title: "Сдать батарейки", timestamp: .now)]),
            onRetry: {}
        )
    }
}
