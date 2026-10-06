import SwiftUI

struct ArticleCoverImage: View {
    private static let placeholderSymbolScale: CGFloat = 0.32

    let tip: EcoTip

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: tip.coverUrl) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder(side: min(proxy.size.width, proxy.size.height))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private func placeholder(side: CGFloat) -> some View {
        return Rectangle()
            .fill(Palette.forestDeep.gradient)
            .overlay {
                Image(systemName: tip.category.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: side * Self.placeholderSymbolScale, height: side * Self.placeholderSymbolScale)
                    .foregroundStyle(Palette.onForest)
            }
    }
}
