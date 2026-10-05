enum FavoritesUserAction {
    case taskSelected(EcoTask)
    case tipSelected(EcoTip)
    case placeSelected(MapPoint)
    case taskRemoved(EcoTask)
    case tipRemoved(EcoTip)
    case placeRemoved(MapPoint)
    case retry
}
