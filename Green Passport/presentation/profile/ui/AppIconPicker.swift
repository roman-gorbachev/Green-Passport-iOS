import SwiftUI

struct AppIconPicker: View {
    private static let iconSize: CGFloat = 64
    private static let iconCornerRatio: CGFloat = 0.225
    private static let selectionLineWidth: CGFloat = 3
    private static let columnCount = 3

    let selected: AppIcon
    let onSelect: (AppIcon) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: Self.columnCount), spacing: Spacing.medium) {
            ForEach(AppIcon.allCases, id: \.self) { icon in
                Button {
                    onSelect(icon)
                } label: {
                    VStack(spacing: Spacing.xSmall) {
                        Image(icon.preview)
                            .resizable()
                            .frame(width: Self.iconSize, height: Self.iconSize)
                            .clipShape(.rect(cornerRadius: Self.iconSize * Self.iconCornerRatio, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: Self.iconSize * Self.iconCornerRatio, style: .continuous)
                                    .stroke(icon == selected ? Palette.forest : .clear, lineWidth: Self.selectionLineWidth)
                            }
                        Text(icon.title)
                            .font(.caption.weight(icon == selected ? .semibold : .regular))
                            .foregroundStyle(icon == selected ? Palette.forest : Color.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(icon == selected ? .isSelected : [])
            }
        }
        .padding(.vertical, Spacing.small)
    }
}

#Preview {
    List {
        AppIconPicker(selected: .night, onSelect: { _ in })
    }
}
