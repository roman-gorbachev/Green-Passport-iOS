import SwiftUI

struct MessageComposer: View {
    private static let lineLimit = 1...5

    @Binding var draft: String
    let placeholder: LocalizedStringResource
    let isSending: Bool
    let errorMessage: LocalizedStringResource?
    let onSend: () -> Void
    var banner: ComposerBanner?
    var onCancelBanner: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            if let banner {
                bannerView(banner)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .padding(.horizontal, Spacing.medium)
            }
            HStack(alignment: .bottom, spacing: Spacing.xSmall) {
                TextField(String(localized: placeholder), text: $draft, axis: .vertical)
                    .lineLimit(Self.lineLimit)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .adaptiveGlassEffect(in: .rect(cornerRadius: CornerRadius.large))
                Button {
                    Keyboard.dismiss()
                    onSend()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .loadingOverlay(isSending, tint: Palette.onForest)
                }
                .adaptiveProminentGlassButtonStyle()
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .accessibilityLabel(Text(.forumPostButton))
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.xSmall)
        .animation(.snappy, value: banner)
    }

    private func bannerView(_ banner: ComposerBanner) -> some View {
        return HStack(spacing: Spacing.small) {
            Image(systemName: banner.systemImage)
                .foregroundStyle(Palette.forest)
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(banner.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                if let text = banner.text {
                    Text(text.isEmpty ? String(localized: .messageDeleted) : text)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onCancelBanner) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
            }
            .accessibilityLabel(Text(.cancel))
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .adaptiveGlassEffect(in: .rect(cornerRadius: CornerRadius.large))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    MessageComposer(
        draft: .constant(""),
        placeholder: .forumDraftLabel,
        isSending: false,
        errorMessage: .messageNotSentMsg,
        onSend: {},
        banner: ComposerBanner(systemImage: "arrowshape.turn.up.left", title: "Ответ Ане", text: "Кто идёт на субботник?")
    )
}
