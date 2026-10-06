enum TasksListUserAction {
    case filtersChanged(TaskFilters)
    case queryChanged(String)
    case favoriteToggled(EcoTask)
    case taskSelected(EcoTask)
    case retry
}
