import SwiftUI

struct AppButton: View {
    let title: LocalizedStringResource
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .loadingOverlay(isLoading, tint: Palette.onForest)
                .frame(maxWidth: .infinity)
        }
        .adaptiveProminentGlassButtonStyle()
        .controlSize(.large)
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack {
        AppButton(title: .next) {}
        AppButton(title: .next, isLoading: true) {}
    }
    .padding()
}
