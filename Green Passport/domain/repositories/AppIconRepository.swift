protocol AppIconRepository {
    var isSupported: Bool { get }
    var current: AppIcon { get }
    func set(_ icon: AppIcon) async throws
}
