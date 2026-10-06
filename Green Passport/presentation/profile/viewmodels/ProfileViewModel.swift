import Observation

@Observable
final class ProfileViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeUserProfile: ObserveUserProfileUseCase
    @ObservationIgnored private let observeIsModerator: ObserveIsModeratorUseCase
    @ObservationIgnored private let observeWallet: ObserveWalletUseCase
    @ObservationIgnored private let signOut: SignOutUseCase
    @ObservationIgnored private let isNotificationCategoryEnabled: IsNotificationCategoryEnabledUseCase
    @ObservationIgnored private let setNotificationCategoryEnabled: SetNotificationCategoryEnabledUseCase
    @ObservationIgnored private let observeMessageNotificationsEnabled: ObserveMessageNotificationsEnabledUseCase
    @ObservationIgnored private let notificationPermission: NotificationPermission
    @ObservationIgnored private let appTheme: AppThemeUseCase
    @ObservationIgnored private let appIcon: AppIconUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var session: AuthSession?
    @ObservationIgnored private var isNotificationPermissionGranted = false
    @ObservationIgnored private var areMessageNotificationsEnabled = true

    private(set) var uiState = ProfileUiState()
    private(set) var notificationSettingsRequests = 0

    init(
        observeSession: ObserveSessionUseCase,
        observeUserProfile: ObserveUserProfileUseCase,
        observeIsModerator: ObserveIsModeratorUseCase,
        observeWallet: ObserveWalletUseCase,
        signOut: SignOutUseCase,
        isNotificationCategoryEnabled: IsNotificationCategoryEnabledUseCase,
        setNotificationCategoryEnabled: SetNotificationCategoryEnabledUseCase,
        observeMessageNotificationsEnabled: ObserveMessageNotificationsEnabledUseCase,
        notificationPermission: NotificationPermission,
        appTheme: AppThemeUseCase,
        appIcon: AppIconUseCase
    ) {
        self.observeSession = observeSession
        self.observeUserProfile = observeUserProfile
        self.observeIsModerator = observeIsModerator
        self.observeWallet = observeWallet
        self.signOut = signOut
        self.isNotificationCategoryEnabled = isNotificationCategoryEnabled
        self.setNotificationCategoryEnabled = setNotificationCategoryEnabled
        self.observeMessageNotificationsEnabled = observeMessageNotificationsEnabled
        self.notificationPermission = notificationPermission
        self.appTheme = appTheme
        self.appIcon = appIcon
        uiState.theme = appTheme.current()
        uiState.appIcon = appIcon.current()
        uiState.isAppIconSupported = appIcon.isSupported
    }

    func observe() async {
        await refreshNotifications()
        for await session in observeSession.execute() {
            guard let session else {
                continue
            }
            self.session = session
            uiState.email = session.email
            uiState.isAnonymous = session.isAnonymous
            start(userId: session.userId)
        }
        sessionTask.cancel()
    }

    func retry() {
        guard let session else {
            return
        }
        uiState.isLoading = true
        uiState.hasError = false
        start(userId: session.userId)
    }

    func toggleNotificationCategory(_ category: NotificationCategory, isEnabled: Bool) {
        Task {
            let authorization = await setNotificationCategoryEnabled.execute(category, isEnabled: isEnabled, userId: session?.userId)
            isNotificationPermissionGranted = authorization == .authorized
            if category == .messages {
                areMessageNotificationsEnabled = isEnabled && isNotificationPermissionGranted
            }
            updateNotificationCategories()
            if isEnabled && authorization == .denied {
                notificationSettingsRequests += 1
            }
        }
    }

    func refreshNotifications() async {
        isNotificationPermissionGranted = await notificationPermission.isAuthorized()
        updateNotificationCategories()
    }

    private func updateNotificationCategories() {
        guard isNotificationPermissionGranted else {
            uiState.enabledNotificationCategories = []
            return
        }
        uiState.enabledNotificationCategories = Set(NotificationCategory.allCases.filter { category in
            switch category {
            case .messages:
                return areMessageNotificationsEnabled
            case .events, .tasks:
                return isNotificationCategoryEnabled.execute(category)
            }
        })
    }

    func selectTheme(_ theme: AppTheme) {
        appTheme.update(theme)
        uiState.theme = theme
    }

    func selectAppIcon(_ icon: AppIcon) {
        let previous = uiState.appIcon
        uiState.appIcon = icon
        Task {
            do {
                try await appIcon.update(icon)
            } catch {
                uiState.appIcon = previous
            }
        }
    }

    func performSignOut() {
        try? signOut.execute()
    }

    private func start(userId: String) {
        sessionTask.run { [weak self] in
            await self?.observeUserData(userId: userId)
        }
    }

    private func observeUserData(userId: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeWalletData(userId: userId) }
            group.addTask { await self.observeProfile(userId: userId) }
            group.addTask { await self.observeModerator(userId: userId) }
            group.addTask { await self.observeMessageNotifications(userId: userId) }
        }
    }

    private func observeMessageNotifications(userId: String) async {
        do {
            for try await isEnabled in observeMessageNotificationsEnabled.execute(userId: userId) {
                areMessageNotificationsEnabled = isEnabled
                updateNotificationCategories()
            }
        } catch {
            return
        }
    }

    private func observeWalletData(userId: String) async {
        do {
            for try await wallet in observeWallet.execute(userId: userId) {
                uiState.points = wallet.availablePoints
                uiState.level = wallet.level
                uiState.isLoading = false
                uiState.hasError = false
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState.isLoading = false
            uiState.hasError = true
        }
    }

    private func observeProfile(userId: String) async {
        do {
            for try await profile in observeUserProfile.execute(userId: userId) {
                uiState.profile = profile
            }
        } catch {
            uiState.profile = nil
        }
    }

    private func observeModerator(userId: String) async {
        do {
            for try await isModerator in observeIsModerator.execute(userId: userId) {
                uiState.isModerator = isModerator
            }
        } catch {
            uiState.isModerator = false
        }
    }
}
