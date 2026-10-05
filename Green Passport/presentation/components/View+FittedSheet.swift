import SwiftUI

extension View {
    func fittedSheetDetent() -> some View {
        return modifier(FittedSheetDetent())
    }

    func reportsSheetContentHeight() -> some View {
        return background {
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        }
    }
}
