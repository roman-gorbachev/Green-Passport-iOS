import SwiftUI

enum Palette {
    private static let tertiaryTextOpacity: Double = 0.6

    static let forest = Color(.forest)
    static let onForest = Color(.onForest)
    static let lime = Color(.lime)
    static let onLime = Color(.onLime)
    static let mintSurface = Color(.mintSurface)
    static let mintSurfaceHigh = Color(.mintSurfaceHigh)
    static let forestDeep = Color(.forestDeep)
    static let screenBackground = Color(.screenBackground)
    static let cardBackground = Color(.cardBackground)
    static let fieldBackground = Color(.fieldBackground)
    static let separator = Color(.separator)
    static let secondaryText = Color(.secondaryText)
    static let tertiaryText = Color(.secondaryText).opacity(tertiaryTextOpacity)
    static let error = Color(.systemRed)
    static let disabledOpacity: Double = 0.4
}
