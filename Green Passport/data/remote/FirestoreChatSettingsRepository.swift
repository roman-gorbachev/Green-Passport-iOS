import FirebaseFirestore

final class FirestoreChatSettingsRepository: ChatSettingsRepository {
    private static let fieldUserId = "userId"
    private static let fieldChatId = "chatId"
    private static let fieldPinned = "pinned"
    private static let fieldArchived = "archived"
    private static let fieldMuted = "muted"
    private static let fieldUpdatedAt = "updatedAtEpochMillis"

    private let firestore: Firestore

    init(firestore: Firestore) {
        self.firestore = firestore
    }

    func observeSettings(userId: String) -> AsyncThrowingStream<[ChatId: ChatSettings], Error> {
        let query = FirestoreCollections.chatSettings(firestore).whereField(Self.fieldUserId, isEqualTo: userId)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: query)) { snapshot in
            let settings = snapshot.documents.compactMap { return Self.settings(from: $0) }
            return Dictionary(settings.map { return ($0.chatId, $0) }, uniquingKeysWith: { first, _ in return first })
        }
    }

    func save(_ settings: ChatSettings, userId: String) async throws {
        let data: [String: Any] = [
            Self.fieldUserId: userId,
            Self.fieldChatId: settings.chatId.rawValue,
            Self.fieldPinned: settings.isPinned,
            Self.fieldArchived: settings.isArchived,
            Self.fieldMuted: settings.isMuted,
            Self.fieldUpdatedAt: EpochMillis.now,
        ]
        try await FirestoreCollections.chatSettings(firestore)
            .document("\(userId)_\(settings.chatId.rawValue)")
            .setData(data)
    }

    private static func settings(from document: DocumentSnapshot) -> ChatSettings? {
        guard let rawChatId = document.string(fieldChatId) else {
            return nil
        }
        let chatId = ChatId(rawValue: rawChatId)
        let defaults = ChatSettings.defaults(for: chatId)
        return ChatSettings(
            chatId: chatId,
            isPinned: document.bool(fieldPinned) ?? defaults.isPinned,
            isArchived: document.bool(fieldArchived) ?? defaults.isArchived,
            isMuted: document.bool(fieldMuted) ?? defaults.isMuted
        )
    }
}
