import SwiftUI

struct BottomSearchField: View {
    @Binding var text: String
    let prompt: LocalizedStringResource

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.secondaryText)
            TextField(String(localized: prompt), text: $text)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.clear))
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .adaptiveGlassEffect(in: .capsule)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.xSmall)
    }
}

#Preview {
    BottomSearchField(text: .constant(""), prompt: .searchTasksPlaceholder)
}
