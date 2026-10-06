final class ObserveMessageNotificationsEnabledUseCase {
    private let messageNotificationsRepository: MessageNotificationsRepository

    init(messageNotificationsRepository: MessageNotificationsRepository) {
        self.messageNotificationsRepository = messageNotificationsRepository
    }

    func execute(userId: String) -> AsyncThrowingStream<Bool, Error> {
        return messageNotificationsRepository.observeIsEnabled(userId: userId)
    }
}
