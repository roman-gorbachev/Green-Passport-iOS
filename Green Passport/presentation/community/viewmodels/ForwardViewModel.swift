import Foundation
import Observation

@Observable
final class ForwardViewModel {
    @ObservationIgnored private let message: MessageTarget
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeMyGroups: ObserveMyGroupsUseCase
    @ObservationIgnored private let forwardMessage: ForwardMessageUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var uiState = ForwardUiState()

    init(
        message: MessageTarget,
        observeSession: ObserveSessionUseCase,
        observeMyGroups: ObserveMyGroupsUseCase,
        forwardMessage: ForwardMessageUseCase
    ) {
        self.message = message
        self.observeSession = observeSession
        self.observeMyGroups = observeMyGroups
        self.forwardMessage = forwardMessage
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            guard let userId = session?.userId else {
                sessionTask.cancel()
                uiState.groups = []
                uiState.isLoading = false
                continue
            }
            sessionTask.run { [weak self] in
                await self?.observeGroups(userId: userId)
            }
        }
        sessionTask.cancel()
    }

    func forward(to chat: ChatId) {
        guard let userId, uiState.sendingChatId == nil, !uiState.isSent else {
            return
        }
        uiState.sendingChatId = chat
        uiState.isSendFailed = false
        uiState.isTextRejected = false
        Task {
            do {
                try await forwardMessage.execute(text: message.text, origin: message.forwardOrigin, to: chat, senderId: userId)
                uiState.isSent = true
            } catch is ContentRejectedError {
                uiState.isTextRejected = true
            } catch {
                uiState.isSendFailed = true
            }
            uiState.sendingChatId = nil
        }
    }

    private func observeGroups(userId: String) async {
        do {
            for try await groups in observeMyGroups.execute(userId: userId) {
                uiState.groups = groups.sorted { return $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                uiState.isLoading = false
            }
        } catch {
            uiState.isLoading = false
        }
    }
}
