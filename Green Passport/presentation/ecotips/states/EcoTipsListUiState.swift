struct EcoTipsListUiState {
    var tips: [EcoTip] = []
    var readTipIds: Set<String> = []
    var bookmarkedTipIds: Set<String> = []
    var filter: EcoTipFilter = .all
    var query = ""
    var isLoading = true
    var hasError = false

    var isSearching: Bool {
        return !query.isBlankSearchQuery
    }

    var dailyTip: EcoTip? {
        guard !isSearching else {
            return nil
        }
        return tips.first { return $0.isDailyTip }
    }

    var visibleTips: [EcoTip] {
        let categoryTips: [EcoTip]
        switch filter {
        case .all:
            categoryTips = tips
        case .category(let category):
            categoryTips = tips.filter { return $0.category == category }
        }
        return categoryTips.filter { return $0.title.matchesSearchQuery(query) }
    }
}
