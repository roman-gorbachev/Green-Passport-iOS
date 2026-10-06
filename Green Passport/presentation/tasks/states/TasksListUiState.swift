struct TasksListUiState {
    private static let cityMatchWeight = 2
    private static let interestMatchWeight = 1

    var tasks: [EcoTask] = []
    var completedTaskIds: Set<String> = []
    var favoriteTaskIds: Set<String> = []
    var pendingTaskIds: Set<String> = []
    var profile: UserProfile?
    var filters = TaskFilters()
    var query = ""
    var isLoading = true
    var hasError = false
    var hasLoadedTasks = false
    var hasLoadedCompletedIds = false
    var hasLoadedProfile = false

    var visibleTasks: [EcoTask] {
        return tasks(for: filters)
    }

    var isSearching: Bool {
        return !query.isBlankSearchQuery
    }

    var filterChips: [TaskFilterChip] {
        return filters.chips(profileCity: profile?.city)
    }

    func tasks(for filters: TaskFilters) -> [EcoTask] {
        let filtered = filters.apply(
            to: tasks,
            completedIds: completedTaskIds,
            pendingIds: pendingTaskIds,
            profileCity: profile?.city
        )
        .filter { return $0.title.matchesSearchQuery(query) }
        guard let profile else {
            return filtered
        }
        return filtered.enumerated().sorted { lhs, rhs in
            let lhsScore = Self.relevance(lhs.element, profile: profile)
            let rhsScore = Self.relevance(rhs.element, profile: profile)
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    private static func relevance(_ task: EcoTask, profile: UserProfile) -> Int {
        let cityScore = task.city == profile.city ? cityMatchWeight : 0
        let interestScore = profile.interests.contains(task.category) ? interestMatchWeight : 0
        return cityScore + interestScore
    }
}
