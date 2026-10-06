final class AppIconUseCase {
    private let appIconRepository: AppIconRepository

    init(appIconRepository: AppIconRepository) {
        self.appIconRepository = appIconRepository
    }

    var isSupported: Bool {
        return appIconRepository.isSupported
    }

    func current() -> AppIcon {
        return appIconRepository.current
    }

    func update(_ icon: AppIcon) async throws {
        try await appIconRepository.set(icon)
    }
}
