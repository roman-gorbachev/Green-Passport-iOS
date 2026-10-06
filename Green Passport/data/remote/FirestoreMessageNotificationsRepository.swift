import FirebaseFirestore

final class FirestoreMessageNotificationsRepository: MessageNotificationsRepository {
    private static let fieldMessageNotificationsEnabled = "messageNotificationsEnabled"

    private let firestore: Firestore

    init(firestore: Firestore) {
        self.firestore = firestore
    }

    func observeIsEnabled(userId: String) -> AsyncThrowingStream<Bool, Error> {
        let document = FirestoreCollections.users(firestore).document(userId)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: document)) { snapshot in
            return snapshot.bool(Self.fieldMessageNotificationsEnabled) ?? true
        }
    }

    func setEnabled(_ isEnabled: Bool, userId: String) async throws {
        try await FirestoreCollections.users(firestore)
            .document(userId)
            .setData([Self.fieldMessageNotificationsEnabled: isEnabled], merge: true)
    }
}
