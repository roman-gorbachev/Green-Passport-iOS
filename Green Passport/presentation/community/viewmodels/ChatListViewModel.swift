import Foundation
import Observation

@Observable
final class ChatListViewModel {
    @ObservationIgnored private let showsArchived: Bool
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeMyGroups: ObserveMyGroupsUseCase
    @ObservationIgnored private let observeLatestForumPostDate: ObserveLatestForumPostDateUseCase
    @ObservationIgnored private let observeChatSettings: ObserveChatSettingsUseCase
    @ObservationIgnored private let updateChatSettings: UpdateChatSettingsUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?
    @ObservationIgnored private var groups: [CommunityGroup] = []
    @ObservationIgnored private var forumLastMessageAt: Date?
    @ObservationIgnored private var settings: [ChatId: ChatSettings] = [:]

    private(set) var uiState = ChatListUiState()

    init(
        showsArchived: Bool,
        observeSession: ObserveSessionUseCase,
        observeMyGroups: ObserveMyGroupsUseCase,
        observeLatestForumPostDate: ObserveLatestForumPostDateUseCase,
        observeChatSettings: ObserveChatSettingsUseCase,
        updateChatSettings: UpdateChatSettingsUseCase
    ) {
        self.showsArchived = showsArchived
        self.observeSession = observeSession
        self.observeMyGroups = observeMyGroups
        self.observeLatestForumPostDate = observeLatestForumPostDate
        self.observeChatSettings = observeChatSettings
        self.updateChatSettings = updateChatSettings
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeUser() }
            group.addTask { await self.observeForumDate() }
        }
        sessionTask.cancel()
    }

    func retry() {
        uiState.isLoading = true
        uiState.hasError = false
        start(userId: userId)
    }

    func handle(_ action: ChatListAction, on chat: ChatSummary) {
        guard let userId else {
            return
        }
        var updated = chat.settings
        switch action {
        case .togglePin:
            updated.isPinned.toggle()
        case .toggleMute:
            updated.isMuted.toggle()
        case .toggleArchive:
            updated.isArchived.toggle()
        }
        settings[chat.chatId] = updated
        rebuild()
        Task {
            try? await updateChatSettings.execute(updated, userId: userId)
        }
    }

    private func observeUser() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            start(userId: session?.userId)
        }
    }

    private func start(userId: String?) {
        groups = []
        settings = [:]
        rebuild()
        guard let userId else {
            sessionTask.cancel()
            uiState.isLoading = false
            return
        }
        sessionTask.run { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self?.observeGroups(userId: userId) }
                group.addTask { await self?.observeSettings(userId: userId) }
            }
        }
    }

    private func observeGroups(userId: String) async {
        do {
            for try await groups in observeMyGroups.execute(userId: userId) {
                self.groups = groups
                uiState.isLoading = false
                uiState.hasError = false
                rebuild()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            uiState.isLoading = false
            uiState.hasError = true
        }
    }

    private func observeSettings(userId: String) async {
        do {
            for try await settings in observeChatSettings.execute(userId: userId) {
                self.settings = settings
                rebuild()
            }
        } catch {
            return
        }
    }

    private func observeForumDate() async {
        do {
            for try await date in observeLatestForumPostDate.execute() {
                forumLastMessageAt = date
                rebuild()
            }
        } catch {
            return
        }
    }

    private func rebuild() {
        let all = ChatSummary.list(groups: groups, forumLastMessageAt: forumLastMessageAt, settings: settings)
        uiState.chats = all.filter { return $0.settings.isArchived == showsArchived }
        uiState.archivedCount = all.filter(\.settings.isArchived).count
    }
}
