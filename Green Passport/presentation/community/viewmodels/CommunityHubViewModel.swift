import Foundation
import Observation

@Observable
final class CommunityHubViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeGroups: ObserveGroupsUseCase
    @ObservationIgnored private let observeLatestForumPostDate: ObserveLatestForumPostDateUseCase
    @ObservationIgnored private let observeChatSettings: ObserveChatSettingsUseCase
    @ObservationIgnored private let updateChatSettings: UpdateChatSettingsUseCase
    @ObservationIgnored private let fetchMembers: FetchGroupMembersUseCase
    @ObservationIgnored private let createGroup: CreateGroupUseCase
    @ObservationIgnored private let joinGroupByCode: JoinGroupByCodeUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var allGroups: [CommunityGroup] = []
    @ObservationIgnored private var forumLastMessageAt: Date?
    @ObservationIgnored private var settings: [ChatId: ChatSettings] = [:]
    @ObservationIgnored private var memberNames: [String: String] = [:]
    @ObservationIgnored private var requestedMemberIds: Set<String> = []

    private(set) var uiState = CommunityHubUiState()

    init(
        observeSession: ObserveSessionUseCase,
        observeGroups: ObserveGroupsUseCase,
        observeLatestForumPostDate: ObserveLatestForumPostDateUseCase,
        observeChatSettings: ObserveChatSettingsUseCase,
        updateChatSettings: UpdateChatSettingsUseCase,
        fetchMembers: FetchGroupMembersUseCase,
        createGroup: CreateGroupUseCase,
        joinGroupByCode: JoinGroupByCodeUseCase
    ) {
        self.observeSession = observeSession
        self.observeGroups = observeGroups
        self.observeLatestForumPostDate = observeLatestForumPostDate
        self.observeChatSettings = observeChatSettings
        self.updateChatSettings = updateChatSettings
        self.fetchMembers = fetchMembers
        self.createGroup = createGroup
        self.joinGroupByCode = joinGroupByCode
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeUser() }
            group.addTask { await self.observeGroupList() }
            group.addTask { await self.observeForumDate() }
        }
        sessionTask.cancel()
    }

    func retry() {
        uiState.isLoading = true
        uiState.hasError = false
    }

    func updateQuery(_ query: String) {
        uiState.query = query
        if uiState.isSearching {
            loadMissingMemberNames()
        }
        rebuild()
    }

    func handle(_ action: ChatListAction, on chat: ChatSummary) {
        guard let userId = uiState.currentUserId else {
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

    func updateGroupDraftName(_ name: String) {
        uiState.groupDraftName = name
        uiState.isGroupNameRejected = false
    }

    func createGroupFromDraft() {
        let name = uiState.groupDraftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let userId = uiState.currentUserId, !name.isEmpty, !uiState.isCreatingGroup else {
            return
        }
        uiState.isCreatingGroup = true
        Task {
            do {
                try await createGroup.execute(name: name, creatorId: userId)
                uiState.groupDraftName = ""
            } catch is ContentRejectedError {
                uiState.isGroupNameRejected = true
            } catch {
                uiState.isGroupNameRejected = false
            }
            uiState.isCreatingGroup = false
        }
    }

    func dismissGroupNameRejected() {
        uiState.isGroupNameRejected = false
    }

    func updateInviteCodeDraft(_ code: String) {
        uiState.inviteCodeDraft = code
    }

    func dismissInviteCodeNotFound() {
        uiState.isInviteCodeNotFound = false
    }

    func joinByCode() async -> String? {
        guard let userId = uiState.currentUserId, !uiState.isJoiningByCode else {
            return nil
        }
        uiState.isJoiningByCode = true
        defer {
            uiState.isJoiningByCode = false
            uiState.inviteCodeDraft = ""
        }
        do {
            let group = try await joinGroupByCode.execute(code: uiState.inviteCodeDraft, userId: userId)
            return group.id
        } catch {
            uiState.isInviteCodeNotFound = true
            return nil
        }
    }

    private func observeUser() async {
        for await session in observeSession.execute() {
            uiState.currentUserId = session?.userId
            settings = [:]
            rebuild()
            guard let userId = session?.userId else {
                sessionTask.cancel()
                continue
            }
            sessionTask.run { [weak self] in
                await self?.observeSettings(userId: userId)
            }
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

    private func observeGroupList() async {
        do {
            for try await groups in observeGroups.execute() {
                allGroups = groups
                uiState.isLoading = false
                uiState.hasError = false
                if uiState.isSearching {
                    loadMissingMemberNames()
                }
                rebuild()
            }
        } catch {
            uiState.isLoading = false
            uiState.hasError = true
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

    private func loadMissingMemberNames() {
        let missing = Set(allGroups.flatMap(\.memberIds)).subtracting(requestedMemberIds)
        guard !missing.isEmpty else {
            return
        }
        requestedMemberIds.formUnion(missing)
        Task {
            guard let members = try? await fetchMembers.execute(memberIds: Array(missing)) else {
                requestedMemberIds.subtract(missing)
                return
            }
            for member in members {
                if let name = member.name {
                    memberNames[member.id] = name
                }
            }
            rebuild()
        }
    }

    private func rebuild() {
        let myGroups = allGroups.filter { group in
            return uiState.currentUserId.map { group.memberIds.contains($0) } ?? false
        }
        let summaries = ChatSummary.groups(myGroups, settings: settings)
        uiState.forum = ChatSummary.forum(lastMessageAt: forumLastMessageAt, settings: settings)
        uiState.groups = summaries.filter { return !$0.settings.isArchived }
        uiState.archivedCount = summaries.count - uiState.groups.count
        let myGroupIds = Set(myGroups.map(\.id))
        let matches = GroupSearch.matches(allGroups, query: uiState.query, memberNames: memberNames)
        uiState.myGroupMatches = matches.filter { return myGroupIds.contains($0.group.id) }
        uiState.otherGroupMatches = matches.filter { return !myGroupIds.contains($0.group.id) }
    }
}
