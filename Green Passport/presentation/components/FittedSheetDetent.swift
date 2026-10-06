import SwiftUI

struct FittedSheetDetent: ViewModifier {
    private static let minimumHeight: CGFloat = 200
    private static let chromeHeight: CGFloat = 32

    @State private var contentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                contentHeight = height
            }
            .presentationDetents([.height(sheetHeight)])
            .presentationBackground(Palette.screenBackground)
            .presentationDragIndicator(.visible)
    }

    private var sheetHeight: CGFloat {
        return max(contentHeight + Self.chromeHeight, Self.minimumHeight)
    }
}
