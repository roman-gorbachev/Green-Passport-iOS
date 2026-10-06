import Foundation
import Observation

@Observable
final class ChatSettingsViewModel {
    @ObservationIgnored private let chatId: ChatId
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeChatSettings: ObserveChatSettingsUseCase
    @ObservationIgnored private let updateChatSettings: UpdateChatSettingsUseCase
    @ObservationIgnored private let sessionTask = LatestTask()
    @ObservationIgnored private var userId: String?

    private(set) var settings: ChatSettings

    init(
        chatId: ChatId,
        observeSession: ObserveSessionUseCase,
        observeChatSettings: ObserveChatSettingsUseCase,
        updateChatSettings: UpdateChatSettingsUseCase
    ) {
        self.chatId = chatId
        self.observeSession = observeSession
        self.observeChatSettings = observeChatSettings
        self.updateChatSettings = updateChatSettings
        settings = .defaults(for: chatId)
    }

    func observe() async {
        for await session in observeSession.execute() {
            userId = session?.userId
            guard let userId = session?.userId else {
                sessionTask.cancel()
                settings = .defaults(for: chatId)
                continue
            }
            sessionTask.run { [weak self] in
                await self?.observeSettings(userId: userId)
            }
        }
        sessionTask.cancel()
    }

    func toggleMute() {
        var updated = settings
        updated.isMuted.toggle()
        save(updated)
    }

    private func save(_ updated: ChatSettings) {
        guard let userId else {
            return
        }
        settings = updated
        Task {
            try? await updateChatSettings.execute(updated, userId: userId)
        }
    }

    private func observeSettings(userId: String) async {
        do {
            for try await allSettings in observeChatSettings.execute(userId: userId) {
                settings = allSettings[chatId] ?? .defaults(for: chatId)
            }
        } catch {
            return
        }
    }
}
