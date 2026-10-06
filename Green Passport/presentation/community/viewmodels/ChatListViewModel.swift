import Foundation
import Observation

@Observable
final class ChatListViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeMyGroups: ObserveMyGroupsUseCase
    @ObservationIgnored private let observeChatSettings: ObserveChatSettingsUseCase
    @ObservationIgnored private let updateChatSettings: UpdateChatSettingsUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?
    @ObservationIgnored private var groups: [CommunityGroup] = []
    @ObservationIgnored private var settings: [ChatId: ChatSettings] = [:]

    private(set) var uiState = ChatListUiState()

    init(
        observeSession: ObserveSessionUseCase,
        observeMyGroups: ObserveMyGroupsUseCase,
        observeChatSettings: ObserveChatSettingsUseCase,
        updateChatSettings: UpdateChatSettingsUseCase
    ) {
        self.observeSession = observeSession
        self.observeMyGroups = observeMyGroups
        self.observeChatSettings = observeChatSettings
        self.updateChatSettings = updateChatSettings
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            start(userId: session?.userId)
        }
        sessionTask.cancel()
    }

    func handle(_ action: ChatListAction, on chat: ChatSummary) {
        guard let userId else {
            return
        }
        let previous = chat.settings
        let updated = chat.settings.applying(action)
        settings[chat.chatId] = updated
        rebuild()
        Task {
            do {
                try await updateChatSettings.execute(updated, userId: userId)
            } catch {
                settings[chat.chatId] = previous
                rebuild()
            }
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
                rebuild()
            }
        } catch {
            uiState.isLoading = false
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

    private func rebuild() {
        uiState.chats = ChatSummary.groups(groups, settings: settings).filter(\.settings.isArchived)
    }
}
