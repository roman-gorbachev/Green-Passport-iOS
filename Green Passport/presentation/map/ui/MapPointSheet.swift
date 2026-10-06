import SwiftUI

struct MapPointSheet: View {
    static let height: CGFloat = 250
    fileprivate static let bottomAllowance: CGFloat = 16
    private static let tileSize: CGFloat = 44

    let point: MapPoint
    let isSaved: Bool
    let onToggleSaved: () -> Void
    let onRoute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                SymbolTile(systemImage: point.type.systemImage, size: Self.tileSize)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(point.name)
                        .font(.title3.bold())
                        .lineLimit(2)
                    Text(point.type.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.forest)
                }
            }
            Label {
                Text(point.address)
            } icon: {
                Image(systemName: "mappin.and.ellipse")
            }
            .font(.subheadline)
            .foregroundStyle(Palette.secondaryText)
            HStack(spacing: Spacing.small) {
                Button(action: onRoute) {
                    Label {
                        Text(.buildRoute)
                    } icon: {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
                .adaptiveProminentGlassButtonStyle()
                Button(action: onToggleSaved) {
                    Label {
                        Text(isSaved ? .saved : .save)
                    } icon: {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .frame(maxWidth: .infinity)
                }
                .adaptiveGlassButtonStyle()
                .sensoryFeedback(.selection, trigger: isSaved)
            }
            .controlSize(.large)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.small)
    }
}

private struct MapPointSheetPresentation: ViewModifier {
    @State private var height = MapPointSheet.height

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                return proxy.size.height
            } action: { measured in
                guard measured > 0 else {
                    return
                }
                height = measured + MapPointSheet.bottomAllowance
            }
            .presentationDetents([.height(height)])
            .presentationBackground(Palette.screenBackground)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(height)))
    }
}

extension View {
    func mapPointSheetPresentation() -> some View {
        return modifier(MapPointSheetPresentation())
    }
}

#Preview {
    MapPointSheet(
        point: MapPoint(id: "1", name: "Пункт приёма", type: .recyclingPoint, address: "ул. Ленина, 1", city: "Минск", latitude: 53.9, longitude: 27.56),
        isSaved: false,
        onToggleSaved: {},
        onRoute: {}
    )
}
