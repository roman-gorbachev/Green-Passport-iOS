import SwiftUI

struct FavoritesScreen: View {
    private static let mascotSize: CGFloat = 34

    let uiState: FavoritesUiState
    @Binding var segment: FavoritesSegment
    let onAction: (FavoritesUserAction) -> Void

    var body: some View {
        List {
            Group {
                switch segment {
                case .tasks:
                    ForEach(uiState.favoriteTasks) { task in
                        Button {
                            onAction(.taskSelected(task))
                        } label: {
                            ListRow(title: task.title, subtitle: String(localized: task.category.title)) {
                                MascotImage(size: Self.mascotSize)
                            } trailing: {
                                PointsBadge(points: task.rewardPoints)
                                FavoriteButton(isFavorite: true) {
                                    onAction(.taskRemoved(task))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .removableFromFavorites { onAction(.taskRemoved(task)) }
                    }
                case .tips:
                    ForEach(uiState.bookmarkedTips) { tip in
                        Button {
                            onAction(.tipSelected(tip))
                        } label: {
                            ListRow(title: tip.title, subtitle: String(localized: tip.category.title)) {
                                SymbolTile(systemImage: tip.category.systemImage)
                            } trailing: {
                                FavoriteButton(isFavorite: true) {
                                    onAction(.tipRemoved(tip))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .removableFromFavorites { onAction(.tipRemoved(tip)) }
                    }
                case .places:
                    ForEach(uiState.savedPlaces) { point in
                        Button {
                            onAction(.placeSelected(point))
                        } label: {
                            ListRow(title: point.name, subtitle: String(localized: point.type.title)) {
                                SymbolTile(systemImage: point.type.systemImage)
                            } trailing: {
                                FavoriteButton(isFavorite: true) {
                                    onAction(.placeRemoved(point))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .removableFromFavorites { onAction(.placeRemoved(point)) }
                    }
                }
            }
            .themedRowBackground()
        }
        .listStyle(.insetGrouped)
        .themedListBackground()
        .animation(.snappy, value: uiState.favoriteTaskIds)
        .animation(.snappy, value: uiState.bookmarkedTipIds)
        .animation(.snappy, value: uiState.savedMapPointIds)
        .safeAreaInset(edge: .top) {
            Picker(selection: $segment) {
                ForEach(FavoritesSegment.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xSmall)
        }
        .overlay {
            overlayState
        }
        .navigationTitle(Text(.favoritesScreenTitle))
    }

    @ViewBuilder
    private var overlayState: some View {
        if uiState.isLoading {
            StateView(kind: .loading)
        } else if uiState.hasError {
            StateView(kind: .error(retry: { onAction(.retry) }))
        } else if segment == .tasks && uiState.favoriteTasks.isEmpty {
            StateView(kind: .empty(message: .favoritesEmpty))
        } else if segment == .tips && uiState.bookmarkedTips.isEmpty {
            StateView(kind: .empty(message: .bookmarksEmpty))
        } else if segment == .places && uiState.savedPlaces.isEmpty {
            StateView(kind: .empty(message: .savedPlacesEmpty))
        }
    }
}

private extension View {
    func removableFromFavorites(_ onRemove: @escaping () -> Void) -> some View {
        return swipeActions(edge: .trailing) {
            Button(action: onRemove) {
                Image(systemName: "heart.slash.fill")
            }
            .tint(Palette.forest)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesScreen(
            uiState: FavoritesUiState(isLoading: false),
            segment: .constant(.tasks),
            onAction: { _ in }
        )
    }
}
