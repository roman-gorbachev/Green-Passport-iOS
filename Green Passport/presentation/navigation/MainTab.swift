import Foundation

enum MainTab: Hashable, CaseIterable {
    case home
    case shop
    case map
    case favorites

    var title: LocalizedStringResource {
        switch self {
        case .home:
            return .home
        case .shop:
            return .shop
        case .map:
            return .map
        case .favorites:
            return .favorites
        }
    }

    var navigationTitle: LocalizedStringResource? {
        switch self {
        case .home, .map:
            return nil
        case .shop:
            return .shop
        case .favorites:
            return .favoritesScreenTitle
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .shop:
            return "bag"
        case .map:
            return "map"
        case .favorites:
            return "heart"
        }
    }
}
