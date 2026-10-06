import SwiftUI

extension View {
    func themedListBackground() -> some View {
        return scrollContentBackground(.hidden)
            .background(Palette.screenBackground)
    }

    func themedRowBackground() -> some View {
        return listRowBackground(Palette.cardBackground)
            .listRowSeparatorTint(Palette.separator)
    }
}
