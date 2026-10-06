import SwiftUI

struct MainTabView: View {
    let container: AppDIContainer

    @State private var router = AppRouter()
    @State private var selectedTab = MainTab.home

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $selectedTab) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Tab(String(localized: tab.title), systemImage: tab.systemImage, value: tab) {
                        root(for: tab)
                    }
                }
            }
            .navigationTitle(selectedTab.navigationTitle.map { return String(localized: $0) } ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(selectedTab.navigationTitle == nil ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: AppDestination.self) { destination in
                AppDestinationView(destination: destination, container: container)
            }
        }
        .environment(router)
    }

    @ViewBuilder
    private func root(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeRoute(container: container)
        case .shop:
            ShopRoute(container: container)
        case .map:
            MapRoute(container: container)
        case .favorites:
            FavoritesRoute(container: container)
        }
    }
}
