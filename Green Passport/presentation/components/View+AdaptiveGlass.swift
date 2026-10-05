import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    @ViewBuilder
    func adaptiveGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func adaptiveProminentGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
