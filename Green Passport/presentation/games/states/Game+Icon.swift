import SwiftUI

extension Game {
    private static let hexRadix = 16
    private static let channelMask = 0xFF
    private static let channelMax = 255.0
    private static let redShift = 16
    private static let greenShift = 8
    private static let gradientColorCount = 2
    private static let fallbackEmoji = "🎮"

    var gradientColors: [Color] {
        let colors = iconColors.compactMap { return Self.color(hex: $0) }
        return colors.count >= Self.gradientColorCount ? colors : [Palette.forestDeep, Palette.forestDeep]
    }

    var tileEmoji: String {
        return iconEmoji ?? Self.fallbackEmoji
    }

    private static func color(hex: String) -> Color? {
        guard let value = Int(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: hexRadix) else {
            return nil
        }
        return Color(
            red: Double((value >> redShift) & channelMask) / channelMax,
            green: Double((value >> greenShift) & channelMask) / channelMax,
            blue: Double(value & channelMask) / channelMax
        )
    }
}
