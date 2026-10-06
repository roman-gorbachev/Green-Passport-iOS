import SwiftUI

extension AppIcon {
    var title: LocalizedStringResource {
        switch self {
        case .standard:
            return .appIconStandard
        case .dark:
            return .appIconDark
        case .sunset:
            return .appIconSunset
        case .night:
            return .appIconNight
        case .ocean:
            return .appIconOcean
        case .lime:
            return .appIconLime
        }
    }

    var preview: ImageResource {
        switch self {
        case .standard:
            return .appIconPreviewStandard
        case .dark:
            return .appIconPreviewDark
        case .sunset:
            return .appIconPreviewSunset
        case .night:
            return .appIconPreviewNight
        case .ocean:
            return .appIconPreviewOcean
        case .lime:
            return .appIconPreviewLime
        }
    }
}
