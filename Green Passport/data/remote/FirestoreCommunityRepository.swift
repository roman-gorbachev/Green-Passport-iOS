import FirebaseFirestore

final class FirestoreCommunityRepository: CommunityRepository {
    private static let fieldAuthorId = "authorId"
    private static let fieldAuthorName = "authorName"
    private static let fieldAuthorAvatar = "authorAvatar"
    private static let fieldText = "text"
    private static let fieldCreatedAt = "createdAtEpochMillis"
    private static let fieldHidden = "hidden"
    private static let fieldReportCount = "reportCount"
    private static let fieldName = "name"
    private static let fieldMemberIds = "memberIds"
    private static let fieldOwnerId = "ownerId"
    private static let fieldInviteCode = "inviteCode"
    private static let fieldSenderId = "senderId"
    private static let fieldSenderName = "senderName"
    private static let fieldSenderAvatar = "senderAvatar"
    private static let fieldFirstName = "firstName"
    private static let fieldLastName = "lastName"
    private static let fieldAvatar = "avatar"
    private static let fieldReplyTo = "replyTo"
    private static let fieldForwardedFrom = "forwardedFrom"
    private static let fieldQuoteMessageId = "messageId"
    private static let fieldQuoteSenderName = "senderName"
    private static let fieldQuoteText = "text"
    private static let fieldEditedAt = "editedAtEpochMillis"
    private static let fieldDeleted = "deleted"
    private static let fieldLastMessageAt = "lastMessageAtEpochMillis"
    private static let messagesLimit = 200
    private static let membersQueryChunkSize = 30

    private let firestore: Firestore

    init(firestore: Firestore) {
        self.firestore = firestore
    }

    func observeForumPosts() -> AsyncThrowingStream<[ForumPost], Error> {
        let query = FirestoreCollections.posts(firestore).order(by: Self.fieldCreatedAt, descending: true)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: query)) { snapshot in
            return snapshot.documents.compactMap { return Self.post(from: $0) }.filter { return !$0.isHidden }
        }
    }

    func observeLatestForumPostDate() -> AsyncThrowingStream<Date?, Error> {
        let query = FirestoreCollections.posts(firestore).order(by: Self.fieldCreatedAt, descending: true).limit(to: 1)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: query)) { snapshot in
            return snapshot.documents.first?.date(Self.fieldCreatedAt)
        }
    }

    func postToForum(
        authorId: String,
        authorName: String?,
        authorAvatar: AvatarStyle?,
        text: String,
        replyTo: MessageQuote?,
        forwardedFrom: ForwardOrigin?
    ) async throws {
        var data: [String: Any] = [
            Self.fieldAuthorId: authorId,
            Self.fieldAuthorName: authorName ?? NSNull(),
            Self.fieldAuthorAvatar: authorAvatar?.rawValue ?? NSNull(),
            Self.fieldText: text,
            Self.fieldCreatedAt: EpochMillis.now,
        ]
        Self.addExtras(to: &data, replyTo: replyTo, forwardedFrom: forwardedFrom)
        _ = try await FirestoreCollections.posts(firestore).addDocument(data: data)
    }

    func observeGroups() -> AsyncThrowingStream<[CommunityGroup], Error> {
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: FirestoreCollections.groups(firestore))) { snapshot in
            return snapshot.documents.compactMap { return Self.group(from: $0) }
        }
    }

    func observeGroup(id: String) -> AsyncThrowingStream<CommunityGroup?, Error> {
        let document = FirestoreCollections.groups(firestore).document(id)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: document)) { snapshot in
            return Self.group(from: snapshot)
        }
    }

    func createGroup(name: String, creatorId: String) async throws {
        let data: [String: Any] = [
            Self.fieldName: name,
            Self.fieldMemberIds: [creatorId],
            Self.fieldOwnerId: creatorId,
            Self.fieldCreatedAt: EpochMillis.now,
            Self.fieldInviteCode: InviteCodeGenerator.generate(),
        ]
        _ = try await FirestoreCollections.groups(firestore).addDocument(data: data)
    }

    func joinGroup(groupId: String, userId: String) async throws {
        try await FirestoreCollections.groups(firestore)
            .document(groupId)
            .updateData([Self.fieldMemberIds: FieldValue.arrayUnion([userId])])
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        try await FirestoreCollections.groups(firestore)
            .document(groupId)
            .updateData([Self.fieldMemberIds: FieldValue.arrayRemove([userId])])
    }

    func findGroup(inviteCode: String) async throws -> CommunityGroup? {
        let snapshot = try await FirestoreCollections.groups(firestore)
            .whereField(Self.fieldInviteCode, isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { return Self.group(from: $0) }
    }

    func observeMessages(groupId: String) -> AsyncThrowingStream<[GroupMessage], Error> {
        let query = FirestoreCollections.chatMessages(firestore, chatId: groupId)
            .order(by: Self.fieldCreatedAt)
            .limit(toLast: Self.messagesLimit)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: query)) { snapshot in
            return snapshot.documents.compactMap { return Self.message(from: $0) }
        }
    }

    func sendMessage(
        groupId: String,
        senderId: String,
        senderName: String?,
        senderAvatar: AvatarStyle?,
        text: String,
        replyTo: MessageQuote?,
        forwardedFrom: ForwardOrigin?
    ) async throws {
        var data: [String: Any] = [
            Self.fieldSenderId: senderId,
            Self.fieldSenderName: senderName ?? NSNull(),
            Self.fieldSenderAvatar: senderAvatar?.rawValue ?? NSNull(),
            Self.fieldText: text,
            Self.fieldCreatedAt: EpochMillis.now,
        ]
        Self.addExtras(to: &data, replyTo: replyTo, forwardedFrom: forwardedFrom)
        _ = try await FirestoreCollections.chatMessages(firestore, chatId: groupId).addDocument(data: data)
    }

    func editMessage(in chat: ChatId, messageId: String, text: String) async throws {
        try await messageReference(in: chat, messageId: messageId).updateData([
            Self.fieldText: text,
            Self.fieldEditedAt: EpochMillis.now,
        ])
    }

    func deleteMessage(in chat: ChatId, messageId: String) async throws {
        try await messageReference(in: chat, messageId: messageId).updateData([
            Self.fieldText: "",
            Self.fieldDeleted: true,
            Self.fieldReplyTo: FieldValue.delete(),
            Self.fieldForwardedFrom: FieldValue.delete(),
        ])
    }

    func observeMyGroups(userId: String) -> AsyncThrowingStream<[CommunityGroup], Error> {
        let query = FirestoreCollections.groups(firestore).whereField(Self.fieldMemberIds, arrayContains: userId)
        return FirestoreStream.mapped(FirestoreStream.snapshots(of: query)) { snapshot in
            return snapshot.documents.compactMap { return Self.group(from: $0) }
        }
    }

    private func messageReference(in chat: ChatId, messageId: String) -> DocumentReference {
        switch chat {
        case .forum:
            return FirestoreCollections.posts(firestore).document(messageId)
        case .group(let id):
            return FirestoreCollections.chatMessages(firestore, chatId: id).document(messageId)
        }
    }

    private static func addExtras(to data: inout [String: Any], replyTo: MessageQuote?, forwardedFrom: ForwardOrigin?) {
        if let replyTo {
            let quote: [String: Any] = [
                fieldQuoteMessageId: replyTo.messageId,
                fieldQuoteSenderName: replyTo.senderName ?? NSNull(),
                fieldQuoteText: replyTo.text,
            ]
            data[fieldReplyTo] = quote
        }
        if let forwardedFrom {
            let origin: [String: Any] = [fieldQuoteSenderName: forwardedFrom.senderName ?? NSNull()]
            data[fieldForwardedFrom] = origin
        }
    }

    private static func quote(from document: DocumentSnapshot) -> MessageQuote? {
        guard let map = document.get(fieldReplyTo) as? [String: Any],
              let messageId = map[fieldQuoteMessageId] as? String else {
            return nil
        }
        return MessageQuote(
            messageId: messageId,
            senderName: map[fieldQuoteSenderName] as? String,
            text: map[fieldQuoteText] as? String ?? ""
        )
    }

    private static func forwardOrigin(from document: DocumentSnapshot) -> ForwardOrigin? {
        guard let map = document.get(fieldForwardedFrom) as? [String: Any] else {
            return nil
        }
        return ForwardOrigin(senderName: map[fieldQuoteSenderName] as? String)
    }

    func fetchMembers(ids: [String]) async throws -> [GroupMember] {
        let chunks = stride(from: 0, to: ids.count, by: Self.membersQueryChunkSize).map { start in
            return Array(ids[start..<min(start + Self.membersQueryChunkSize, ids.count)])
        }
        let users = FirestoreCollections.users(firestore)
        var membersById: [String: GroupMember] = [:]
        for chunk in chunks {
            let snapshot = try await users.whereField(FieldPath.documentID(), in: chunk).getDocuments()
            for document in snapshot.documents {
                membersById[document.documentID] = Self.member(from: document)
            }
        }
        return ids.map { id in
            return membersById[id] ?? GroupMember(id: id, name: nil, avatar: .lime)
        }
    }

    private static func group(from document: DocumentSnapshot) -> CommunityGroup? {
        guard let name = document.string(fieldName) else {
            return nil
        }
        return CommunityGroup(
            id: document.documentID,
            name: name,
            memberIds: document.strings(fieldMemberIds),
            ownerId: document.string(fieldOwnerId),
            inviteCode: document.string(fieldInviteCode),
            lastMessageAt: document.date(fieldLastMessageAt)
        )
    }

    private static func message(from document: DocumentSnapshot) -> GroupMessage? {
        guard let senderId = document.string(fieldSenderId),
              let text = document.string(fieldText),
              let sentAt = document.date(fieldCreatedAt) else {
            return nil
        }
        return GroupMessage(
            id: document.documentID,
            senderId: senderId,
            senderName: document.string(fieldSenderName),
            senderAvatar: document.string(fieldSenderAvatar).flatMap(AvatarStyle.init(rawValue:)),
            text: text,
            sentAt: sentAt,
            replyTo: quote(from: document),
            forwardedFrom: forwardOrigin(from: document),
            isEdited: document.date(fieldEditedAt) != nil,
            isDeleted: document.bool(fieldDeleted) ?? false
        )
    }

    private static func member(from document: DocumentSnapshot) -> GroupMember {
        let name = "\(document.string(fieldFirstName) ?? "") \(document.string(fieldLastName) ?? "")"
            .trimmingCharacters(in: .whitespaces)
        return GroupMember(
            id: document.documentID,
            name: name.isEmpty ? nil : name,
            avatar: document.string(fieldAvatar).flatMap(AvatarStyle.init(rawValue:)) ?? .lime
        )
    }

    static func post(from document: DocumentSnapshot) -> ForumPost? {
        guard let authorId = document.string(fieldAuthorId),
              let text = document.string(fieldText),
              let createdAt = document.date(fieldCreatedAt) else {
            return nil
        }
        return ForumPost(
            id: document.documentID,
            authorId: authorId,
            authorName: document.string(fieldAuthorName),
            authorAvatar: document.string(fieldAuthorAvatar).flatMap(AvatarStyle.init(rawValue:)),
            text: text,
            createdAt: createdAt,
            isHidden: document.bool(fieldHidden) ?? false,
            reportCount: document.int(fieldReportCount) ?? 0,
            replyTo: quote(from: document),
            forwardedFrom: forwardOrigin(from: document),
            isEdited: document.date(fieldEditedAt) != nil,
            isDeleted: document.bool(fieldDeleted) ?? false
        )
    }
}
