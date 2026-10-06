extension ForumPost {
    func target(currentUserId: String?) -> MessageTarget {
        return MessageTarget(
            id: id,
            senderName: authorName,
            text: text,
            isOwn: authorId == currentUserId,
            isDeleted: isDeleted,
            canReport: currentUserId != nil && authorId != currentUserId,
            forwardedFrom: forwardedFrom
        )
    }
}
