import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? Palette.forest : Palette.secondaryText)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(.profileFavorites))
        .sensoryFeedback(.impact, trigger: isFavorite)
    }
}

#Preview {
    HStack {
        FavoriteButton(isFavorite: true, action: {})
        FavoriteButton(isFavorite: false, action: {})
    }
}
