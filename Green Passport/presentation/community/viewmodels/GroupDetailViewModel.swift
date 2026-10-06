import Foundation
import Observation

@Observable
final class GroupDetailViewModel {
    @ObservationIgnored private let groupId: String
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeGroup: ObserveGroupUseCase
    @ObservationIgnored private let observeMessages: ObserveGroupMessagesUseCase
    @ObservationIgnored private let sendMessage: SendGroupMessageUseCase
    @ObservationIgnored private let joinGroup: JoinGroupUseCase
    @ObservationIgnored private let leaveGroup: LeaveGroupUseCase
    @ObservationIgnored private let fetchMembers: FetchGroupMembersUseCase
    @ObservationIgnored private let editMessage: EditMessageUseCase
    @ObservationIgnored private let deleteMessage: DeleteMessageUseCase
    @ObservationIgnored private var messagesTask: Task<Void, Never>?

    private(set) var uiState = GroupDetailUiState()
    private(set) var copiedCount = 0

    init(
        groupId: String,
        observeSession: ObserveSessionUseCase,
        observeGroup: ObserveGroupUseCase,
        observeMessages: ObserveGroupMessagesUseCase,
        sendMessage: SendGroupMessageUseCase,
        joinGroup: JoinGroupUseCase,
        leaveGroup: LeaveGroupUseCase,
        fetchMembers: FetchGroupMembersUseCase,
        editMessage: EditMessageUseCase,
        deleteMessage: DeleteMessageUseCase
    ) {
        self.groupId = groupId
        self.observeSession = observeSession
        self.observeGroup = observeGroup
        self.observeMessages = observeMessages
        self.sendMessage = sendMessage
        self.joinGroup = joinGroup
        self.leaveGroup = leaveGroup
        self.fetchMembers = fetchMembers
        self.editMessage = editMessage
        self.deleteMessage = deleteMessage
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeUser() }
            group.addTask { await self.observeGroupDocument() }
        }
        stopMessages()
    }

    func updateDraft(_ text: String) {
        uiState.draft = text
        uiState.isTextRejected = false
        uiState.isSendFailed = false
    }

    func send() {
        let text = uiState.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let userId = uiState.currentUserId, uiState.isMember, !text.isEmpty, !uiState.isSending else {
            return
        }
        uiState.isSending = true
        uiState.isSendFailed = false
        let mode = uiState.composerMode
        Task {
            do {
                switch mode {
                case .new:
                    try await sendMessage.execute(groupId: groupId, senderId: userId, text: text)
                case .reply(let quote):
                    try await sendMessage.execute(groupId: groupId, senderId: userId, text: text, replyTo: quote)
                case .edit(let messageId):
                    try await editMessage.execute(chat: .group(id: groupId), messageId: messageId, text: text)
                }
                uiState.draft = ""
                uiState.composerMode = .new
            } catch is ContentRejectedError {
                uiState.isTextRejected = true
            } catch {
                uiState.isSendFailed = true
            }
            uiState.isSending = false
        }
    }

    func handle(_ action: MessageAction, on target: MessageTarget) {
        switch action {
        case .reply:
            uiState.composerMode = .reply(target.quote)
        case .copy:
            Clipboard.copy(target.text)
            copiedCount += 1
        case .edit:
            uiState.composerMode = .edit(messageId: target.id)
            updateDraft(target.text)
        case .delete:
            delete(target)
        case .forward, .report:
            return
        }
    }

    func cancelComposerMode() {
        if case .edit = uiState.composerMode {
            uiState.draft = ""
        }
        uiState.composerMode = .new
    }

    func join() {
        guard let userId = uiState.currentUserId, !uiState.isJoining else {
            return
        }
        uiState.isJoining = true
        Task {
            try? await joinGroup.execute(groupId: groupId, userId: userId)
            uiState.isJoining = false
            updateMessagesObservation()
        }
    }

    func leave() {
        guard let userId = uiState.currentUserId, !uiState.isLeaving else {
            return
        }
        uiState.isLeaving = true
        stopMessages()
        Task {
            try? await leaveGroup.execute(groupId: groupId, userId: userId)
            uiState.isLeaving = false
            updateMessagesObservation()
        }
    }

    func loadMembers() async {
        guard let memberIds = uiState.group?.memberIds else {
            return
        }
        uiState.isLoadingMembers = true
        uiState.members = (try? await fetchMembers.execute(memberIds: memberIds)) ?? []
        uiState.isLoadingMembers = false
    }

    func retryMessages() {
        stopMessages()
        updateMessagesObservation()
    }

    private func delete(_ target: MessageTarget) {
        if case .edit(let messageId) = uiState.composerMode, messageId == target.id {
            cancelComposerMode()
        }
        Task {
            try? await deleteMessage.execute(chat: .group(id: groupId), messageId: target.id)
        }
    }

    private func observeUser() async {
        for await session in observeSession.execute() {
            uiState.currentUserId = session?.userId
            updateMessagesObservation()
        }
    }

    private func observeGroupDocument() async {
        do {
            for try await group in observeGroup.execute(groupId: groupId) {
                uiState.group = group
                uiState.isLoading = false
                uiState.hasError = group == nil
                updateMessagesObservation()
            }
        } catch {
            uiState.isLoading = false
            uiState.hasError = true
        }
    }

    private func updateMessagesObservation() {
        guard uiState.isMember, !uiState.isJoining, !uiState.isLeaving else {
            if !uiState.isJoining {
                stopMessages()
            }
            return
        }
        guard messagesTask == nil else {
            return
        }
        messagesTask = Task { [weak self] in
            await self?.observeMessageList()
        }
    }

    private func stopMessages() {
        messagesTask?.cancel()
        messagesTask = nil
        uiState.messages = []
        uiState.isLoadingMessages = true
        uiState.hasMessagesError = false
    }

    private func observeMessageList() async {
        do {
            for try await messages in observeMessages.execute(groupId: groupId) {
                uiState.messages = messages
                uiState.isLoadingMessages = false
                uiState.hasMessagesError = false
            }
        } catch {
            if !Task.isCancelled {
                uiState.isLoadingMessages = false
                uiState.hasMessagesError = true
            }
        }
    }
}
