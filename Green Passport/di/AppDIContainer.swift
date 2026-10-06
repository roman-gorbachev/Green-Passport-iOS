import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage
import SwiftData

final class AppDIContainer {
    private static let functionsRegion = "europe-central2"

    private lazy var firestore = Firestore.firestore()
    private lazy var auth = Auth.auth()
    private lazy var functions = Functions.functions(region: Self.functionsRegion)
    private lazy var storage = Storage.storage()
    private lazy var localStore = LocalStore.makeContainer()

    private lazy var textModerator: TextModerator = WordListTextModerator()
    private lazy var authRepository: AuthRepository = FirebaseAuthRepository(
        auth: auth,
        googleSignInProvider: GoogleSignInProvider()
    )
    private lazy var userProfileRepository: UserProfileRepository = FirestoreUserProfileRepository(firestore: firestore)
    private lazy var settingsRepository: SettingsRepository = UserDefaultsSettingsRepository()
    private lazy var tasksRepository: TasksRepository = FirestoreTasksRepository(firestore: firestore)
    private lazy var pointsRepository: PointsRepository = FirestorePointsRepository(firestore: firestore)
    private lazy var eventsRepository: EventsRepository = FirestoreEventsRepository(firestore: firestore)
    private lazy var shopRepository: ShopRepository = FirestoreShopRepository(firestore: firestore)
    private lazy var ecoTipsRepository: EcoTipsRepository = FirestoreEcoTipsRepository(firestore: firestore)
    private lazy var communityRepository: CommunityRepository = FirestoreCommunityRepository(firestore: firestore)
    private lazy var chatSettingsRepository: ChatSettingsRepository = FirestoreChatSettingsRepository(firestore: firestore)
    private lazy var favoritesRepository: FavoritesRepository = FirestoreFavoritesRepository(firestore: firestore)
    private lazy var moderationRepository: ModerationRepository = FirebaseModerationRepository(
        firestore: firestore,
        functions: functions
    )
    private lazy var taskSubmissionsRepository: TaskSubmissionsRepository = FirebaseTaskSubmissionsRepository(
        firestore: firestore,
        storage: storage
    )
    private lazy var mapPointsRepository: MapPointsRepository = FirestoreMapPointsRepository(firestore: firestore)
    private lazy var savedMapPointsRepository: SavedMapPointsRepository = UserDefaultsSavedMapPointsRepository()
    private lazy var locationRepository: LocationRepository = CoreLocationRepository()
    private lazy var feedbackRepository: FeedbackRepository = FirestoreFeedbackRepository(firestore: firestore)
    private lazy var gamesRepository: GamesRepository = FirestoreGamesRepository(firestore: firestore)
    private lazy var gameProgressRepository: GameProgressRepository = SwiftDataGameProgressRepository(container: localStore)
    private lazy var notificationLogRepository: NotificationLogRepository = SwiftDataNotificationLogRepository(
        container: localStore
    )
    private lazy var notificationPermission: NotificationPermission = UserNotificationPermission()
    private lazy var rewardNotifier: RewardNotifier = LocalRewardNotifier(
        settingsRepository: settingsRepository,
        notificationLogRepository: notificationLogRepository
    )
    private lazy var rewardsRepository: RewardsRepository = FirebaseRewardsRepository(
        functions: functions,
        rewardNotifier: rewardNotifier
    )
    private lazy var reminderScheduler: ReminderScheduler = LocalNotificationReminderScheduler(
        settingsRepository: settingsRepository,
        notificationLogRepository: notificationLogRepository,
        notificationPermission: notificationPermission
    )
    private lazy var achievementsRepository: AchievementsRepository = DerivedAchievementsRepository(
        tasksRepository: tasksRepository,
        eventsRepository: eventsRepository,
        ecoTipsRepository: ecoTipsRepository,
        communityRepository: communityRepository,
        pointsRepository: pointsRepository
    )
    private lazy var historyRepository: HistoryRepository = FirestoreHistoryRepository(
        firestore: firestore,
        tasksRepository: tasksRepository,
        eventsRepository: eventsRepository,
        shopRepository: shopRepository
    )

    private lazy var observeSessionUseCase = ObserveSessionUseCase(authRepository: authRepository)
    private lazy var observeUserProfileUseCase = ObserveUserProfileUseCase(userProfileRepository: userProfileRepository)
    private lazy var signOutUseCase = SignOutUseCase(authRepository: authRepository)
    private lazy var observeWalletUseCase = ObserveWalletUseCase(pointsRepository: pointsRepository)
    private lazy var observeTasksUseCase = ObserveTasksUseCase(tasksRepository: tasksRepository)
    private lazy var observeCompletedTaskIdsUseCase = ObserveCompletedTaskIdsUseCase(tasksRepository: tasksRepository)
    private lazy var observeEventsUseCase = ObserveEventsUseCase(eventsRepository: eventsRepository)
    private lazy var observeTaskSubmissionsUseCase = ObserveTaskSubmissionsUseCase(
        taskSubmissionsRepository: taskSubmissionsRepository
    )
    private lazy var observeEcoTipsUseCase = ObserveEcoTipsUseCase(ecoTipsRepository: ecoTipsRepository)
    private lazy var observeReadTipIdsUseCase = ObserveReadTipIdsUseCase(ecoTipsRepository: ecoTipsRepository)
    private lazy var observeCouponsUseCase = ObserveCouponsUseCase(shopRepository: shopRepository)
    private lazy var observeIsModeratorUseCase = ObserveIsModeratorUseCase(moderationRepository: moderationRepository)
}

extension AppDIContainer {
    func buildRootViewModel() -> RootViewModel {
        return RootViewModel(
            observeSession: observeSessionUseCase,
            observeUserProfile: observeUserProfileUseCase,
            isOnboardingSeen: IsOnboardingSeenUseCase(settingsRepository: settingsRepository),
            markOnboardingSeen: MarkOnboardingSeenUseCase(settingsRepository: settingsRepository)
        )
    }

    func buildAuthViewModel() -> AuthViewModel {
        return AuthViewModel(
            signInWithEmail: SignInWithEmailUseCase(authRepository: authRepository),
            registerWithEmail: RegisterWithEmailUseCase(authRepository: authRepository),
            signInAnonymously: SignInAnonymouslyUseCase(authRepository: authRepository),
            signInWithGoogle: SignInWithGoogleUseCase(authRepository: authRepository),
            signInWithApple: SignInWithAppleUseCase(authRepository: authRepository)
        )
    }

    func buildProfileSetupViewModel() -> ProfileSetupViewModel {
        return ProfileSetupViewModel(
            observeSession: observeSessionUseCase,
            observeUserProfile: observeUserProfileUseCase,
            saveUserProfile: SaveUserProfileUseCase(
                userProfileRepository: userProfileRepository,
                textModerator: textModerator
            ),
            isTextAllowed: IsTextAllowedUseCase(textModerator: textModerator),
            signOut: signOutUseCase
        )
    }
}

extension AppDIContainer {
    func buildHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            observeSession: observeSessionUseCase,
            observeUserProfile: observeUserProfileUseCase,
            observeTasks: observeTasksUseCase,
            observeCompletedTaskIds: observeCompletedTaskIdsUseCase,
            rankPendingTasks: RankPendingTasksUseCase(),
            observeWallet: observeWalletUseCase,
            observeUpcomingEvent: ObserveUpcomingEventUseCase(eventsRepository: eventsRepository),
            updateStreakReminder: UpdateStreakReminderUseCase(reminderScheduler: reminderScheduler)
        )
    }

    func buildTasksListViewModel() -> TasksListViewModel {
        return TasksListViewModel(
            observeSession: observeSessionUseCase,
            observeUserProfile: observeUserProfileUseCase,
            observeTasks: observeTasksUseCase,
            observeCompletedTaskIds: observeCompletedTaskIdsUseCase,
            observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase(favoritesRepository: favoritesRepository),
            toggleTaskFavorite: ToggleTaskFavoriteUseCase(favoritesRepository: favoritesRepository),
            observeTaskSubmissions: observeTaskSubmissionsUseCase
        )
    }

    func buildTaskDetailViewModel(taskId: String) -> TaskDetailViewModel {
        return TaskDetailViewModel(
            taskId: taskId,
            observeSession: observeSessionUseCase,
            observeTask: ObserveTaskUseCase(tasksRepository: tasksRepository),
            observeCompletedTaskIds: observeCompletedTaskIdsUseCase,
            completeSelfTask: CompleteSelfTaskUseCase(rewardsRepository: rewardsRepository),
            redeemTaskCode: RedeemTaskCodeUseCase(rewardsRepository: rewardsRepository),
            submitTaskPhoto: SubmitTaskPhotoUseCase(
                photoCompressor: JpegPhotoCompressor(),
                userProfileRepository: userProfileRepository,
                taskSubmissionsRepository: taskSubmissionsRepository
            ),
            observeTaskSubmissions: observeTaskSubmissionsUseCase,
            observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase(favoritesRepository: favoritesRepository),
            toggleTaskFavorite: ToggleTaskFavoriteUseCase(favoritesRepository: favoritesRepository)
        )
    }

    func buildEventDetailViewModel(eventId: String) -> EventDetailViewModel {
        return EventDetailViewModel(
            eventId: eventId,
            observeSession: observeSessionUseCase,
            observeEvents: ObserveEventsUseCase(eventsRepository: eventsRepository, includesArchived: true),
            observeRegisteredEventIds: ObserveRegisteredEventIdsUseCase(eventsRepository: eventsRepository),
            registerForEvent: RegisterForEventUseCase(
                eventsRepository: eventsRepository,
                reminderScheduler: reminderScheduler
            ),
            observeAttendedEventIds: ObserveAttendedEventIdsUseCase(eventsRepository: eventsRepository),
            checkInEvent: CheckInEventUseCase(rewardsRepository: rewardsRepository)
        )
    }

    func buildProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(
            observeSession: observeSessionUseCase,
            observeUserProfile: observeUserProfileUseCase,
            observeIsModerator: observeIsModeratorUseCase,
            observeWallet: observeWalletUseCase,
            signOut: signOutUseCase,
            isNotificationsEnabled: IsNotificationsEnabledUseCase(settingsRepository: settingsRepository),
            setNotificationsEnabled: SetNotificationsEnabledUseCase(
                settingsRepository: settingsRepository,
                notificationPermission: notificationPermission,
                reminderScheduler: reminderScheduler
            ),
            notificationPermission: notificationPermission,
            appTheme: AppThemeUseCase(settingsRepository: settingsRepository)
        )
    }

    func buildAchievementsViewModel() -> AchievementsViewModel {
        return AchievementsViewModel(
            observeSession: observeSessionUseCase,
            fetchAchievements: FetchAchievementsUseCase(achievementsRepository: achievementsRepository)
        )
    }

    func buildHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            observeSession: observeSessionUseCase,
            fetchHistory: FetchHistoryUseCase(historyRepository: historyRepository)
        )
    }
}

extension AppDIContainer {
    func buildShopViewModel() -> ShopViewModel {
        return ShopViewModel(
            observeSession: observeSessionUseCase,
            observeRewards: ObserveRewardsUseCase(shopRepository: shopRepository),
            observeCoupons: observeCouponsUseCase,
            observeWallet: observeWalletUseCase,
            purchaseReward: PurchaseRewardUseCase(rewardsRepository: rewardsRepository, reminderScheduler: reminderScheduler)
        )
    }

    func buildCalendarViewModel() -> CalendarViewModel {
        return CalendarViewModel(
            observeSession: observeSessionUseCase,
            observeEvents: observeEventsUseCase,
            observeRegisteredEventIds: ObserveRegisteredEventIdsUseCase(eventsRepository: eventsRepository)
        )
    }

    func buildMapViewModel() -> MapViewModel {
        return MapViewModel(
            observeMapPoints: ObserveMapPointsUseCase(mapPointsRepository: mapPointsRepository),
            savedMapPointIds: SavedMapPointIdsUseCase(savedMapPointsRepository: savedMapPointsRepository),
            toggleSavedMapPoint: ToggleSavedMapPointUseCase(savedMapPointsRepository: savedMapPointsRepository),
            resolveMapFocus: ResolveMapFocusUseCase(
                locationRepository: locationRepository,
                authRepository: authRepository,
                userProfileRepository: userProfileRepository
            )
        )
    }

    func buildFavoritesViewModel() -> FavoritesViewModel {
        return FavoritesViewModel(
            observeSession: observeSessionUseCase,
            observeTasks: observeTasksUseCase,
            observeEcoTips: observeEcoTipsUseCase,
            observeMapPoints: ObserveMapPointsUseCase(mapPointsRepository: mapPointsRepository),
            observeFavoriteTaskIds: ObserveFavoriteTaskIdsUseCase(favoritesRepository: favoritesRepository),
            observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase(favoritesRepository: favoritesRepository),
            savedMapPointIds: SavedMapPointIdsUseCase(savedMapPointsRepository: savedMapPointsRepository),
            toggleSavedMapPoint: ToggleSavedMapPointUseCase(savedMapPointsRepository: savedMapPointsRepository),
            toggleTaskFavorite: ToggleTaskFavoriteUseCase(favoritesRepository: favoritesRepository),
            toggleTipBookmark: ToggleTipBookmarkUseCase(favoritesRepository: favoritesRepository)
        )
    }
}

extension AppDIContainer {
    func buildForumViewModel() -> ForumViewModel {
        return ForumViewModel(
            observeSession: observeSessionUseCase,
            observeForumPosts: ObserveForumPostsUseCase(communityRepository: communityRepository),
            postToForum: PostToForumUseCase(
                communityRepository: communityRepository,
                userProfileRepository: userProfileRepository,
                textModerator: textModerator
            ),
            reportPost: ReportPostUseCase(moderationRepository: moderationRepository),
            editMessage: EditMessageUseCase(communityRepository: communityRepository, textModerator: textModerator),
            deleteMessage: DeleteMessageUseCase(communityRepository: communityRepository)
        )
    }

    func buildChatSettingsViewModel(chatId: ChatId) -> ChatSettingsViewModel {
        return ChatSettingsViewModel(
            chatId: chatId,
            observeSession: observeSessionUseCase,
            observeChatSettings: ObserveChatSettingsUseCase(chatSettingsRepository: chatSettingsRepository),
            updateChatSettings: UpdateChatSettingsUseCase(chatSettingsRepository: chatSettingsRepository)
        )
    }

    func buildChatListViewModel(showsArchived: Bool) -> ChatListViewModel {
        return ChatListViewModel(
            showsArchived: showsArchived,
            observeSession: observeSessionUseCase,
            observeMyGroups: ObserveMyGroupsUseCase(communityRepository: communityRepository),
            observeLatestForumPostDate: ObserveLatestForumPostDateUseCase(communityRepository: communityRepository),
            observeChatSettings: ObserveChatSettingsUseCase(chatSettingsRepository: chatSettingsRepository),
            updateChatSettings: UpdateChatSettingsUseCase(chatSettingsRepository: chatSettingsRepository)
        )
    }

    func buildForwardViewModel(message: MessageTarget) -> ForwardViewModel {
        return ForwardViewModel(
            message: message,
            observeSession: observeSessionUseCase,
            observeMyGroups: ObserveMyGroupsUseCase(communityRepository: communityRepository),
            forwardMessage: ForwardMessageUseCase(
                postToForum: PostToForumUseCase(
                    communityRepository: communityRepository,
                    userProfileRepository: userProfileRepository,
                    textModerator: textModerator
                ),
                sendGroupMessage: SendGroupMessageUseCase(
                    communityRepository: communityRepository,
                    userProfileRepository: userProfileRepository,
                    textModerator: textModerator
                )
            )
        )
    }

    func buildGroupsViewModel() -> GroupsViewModel {
        return GroupsViewModel(
            observeSession: observeSessionUseCase,
            observeGroups: ObserveGroupsUseCase(communityRepository: communityRepository),
            createGroup: CreateGroupUseCase(communityRepository: communityRepository, textModerator: textModerator),
            joinGroup: JoinGroupUseCase(communityRepository: communityRepository),
            joinGroupByCode: JoinGroupByCodeUseCase(communityRepository: communityRepository)
        )
    }

    func buildGroupDetailViewModel(groupId: String) -> GroupDetailViewModel {
        return GroupDetailViewModel(
            groupId: groupId,
            observeSession: observeSessionUseCase,
            observeGroup: ObserveGroupUseCase(communityRepository: communityRepository),
            observeMessages: ObserveGroupMessagesUseCase(communityRepository: communityRepository),
            sendMessage: SendGroupMessageUseCase(
                communityRepository: communityRepository,
                userProfileRepository: userProfileRepository,
                textModerator: textModerator
            ),
            joinGroup: JoinGroupUseCase(communityRepository: communityRepository),
            leaveGroup: LeaveGroupUseCase(communityRepository: communityRepository),
            fetchMembers: FetchGroupMembersUseCase(communityRepository: communityRepository),
            editMessage: EditMessageUseCase(communityRepository: communityRepository, textModerator: textModerator),
            deleteMessage: DeleteMessageUseCase(communityRepository: communityRepository)
        )
    }

    func buildEcoTipsListViewModel() -> EcoTipsListViewModel {
        return EcoTipsListViewModel(
            observeSession: observeSessionUseCase,
            observeEcoTips: observeEcoTipsUseCase,
            observeReadTipIds: observeReadTipIdsUseCase,
            observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase(favoritesRepository: favoritesRepository),
            toggleTipBookmark: ToggleTipBookmarkUseCase(favoritesRepository: favoritesRepository)
        )
    }

    func buildEcoTipDetailViewModel(tipId: String) -> EcoTipDetailViewModel {
        return EcoTipDetailViewModel(
            tipId: tipId,
            observeSession: observeSessionUseCase,
            observeEcoTips: ObserveEcoTipsUseCase(ecoTipsRepository: ecoTipsRepository, includesArchived: true),
            observeReadTipIds: observeReadTipIdsUseCase,
            markTipRead: MarkTipReadUseCase(rewardsRepository: rewardsRepository),
            observeBookmarkedTipIds: ObserveBookmarkedTipIdsUseCase(favoritesRepository: favoritesRepository),
            toggleTipBookmark: ToggleTipBookmarkUseCase(favoritesRepository: favoritesRepository)
        )
    }

    func buildFeedbackViewModel() -> FeedbackViewModel {
        return FeedbackViewModel(
            observeSession: observeSessionUseCase,
            submitFeedback: SubmitFeedbackUseCase(rewardsRepository: rewardsRepository, textModerator: textModerator),
            fetchActiveSurvey: FetchActiveSurveyUseCase(feedbackRepository: feedbackRepository),
            hasAnsweredSurvey: HasAnsweredSurveyUseCase(feedbackRepository: feedbackRepository),
            submitSurveyAnswer: SubmitSurveyAnswerUseCase(rewardsRepository: rewardsRepository)
        )
    }
}

extension AppDIContainer {
    func buildGamesHubViewModel() -> GamesHubViewModel {
        return GamesHubViewModel(
            observeGames: ObserveGamesUseCase(gamesRepository: gamesRepository),
            fetchBestScores: FetchBestScoresUseCase(gameProgressRepository: gameProgressRepository)
        )
    }

    func buildGameWebViewModel(game: Game) -> GameWebViewModel {
        return GameWebViewModel(
            game: game,
            submitGameResult: SubmitGameResultUseCase(
                gameProgressRepository: gameProgressRepository,
                rewardsRepository: rewardsRepository,
                authRepository: authRepository
            ),
            gameUrl: GameUrlUseCase(gamesRepository: gamesRepository)
        )
    }

    func buildModerationViewModel() -> ModerationViewModel {
        return ModerationViewModel(
            observeSession: observeSessionUseCase,
            observeIsModerator: observeIsModeratorUseCase,
            observePendingSubmissions: ObservePendingSubmissionsUseCase(moderationRepository: moderationRepository),
            observeFlaggedPosts: ObserveFlaggedPostsUseCase(moderationRepository: moderationRepository),
            observeTasks: ObserveTasksUseCase(tasksRepository: tasksRepository, includesArchived: true),
            fetchSubmissionPhotoUrl: FetchSubmissionPhotoUrlUseCase(taskSubmissionsRepository: taskSubmissionsRepository),
            reviewSubmission: ReviewSubmissionUseCase(moderationRepository: moderationRepository),
            moderatePost: ModeratePostUseCase(moderationRepository: moderationRepository)
        )
    }

    func buildNotificationsViewModel() -> NotificationsViewModel {
        return NotificationsViewModel(
            fetchNotificationLog: FetchNotificationLogUseCase(notificationLogRepository: notificationLogRepository)
        )
    }
}

extension AppDIContainer {
    func buildCouponsViewModel() -> CouponsViewModel {
        return CouponsViewModel(observeSession: observeSessionUseCase, observeCoupons: observeCouponsUseCase)
    }

    func buildCouponDetailViewModel(item: CouponItem) -> CouponDetailViewModel {
        return CouponDetailViewModel(
            item: item,
            observeCoupon: ObserveCouponUseCase(shopRepository: shopRepository),
            couponQrPayload: CouponQrPayloadUseCase(shopRepository: shopRepository),
            markCouponUsed: MarkCouponUsedUseCase(rewardsRepository: rewardsRepository, reminderScheduler: reminderScheduler)
        )
    }
}
