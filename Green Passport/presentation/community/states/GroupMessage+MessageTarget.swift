extension GroupMessage {
    func target(currentUserId: String?) -> MessageTarget {
        return MessageTarget(
            id: id,
            senderName: senderName,
            text: text,
            isOwn: senderId == currentUserId,
            isDeleted: isDeleted,
            canReport: false,
            forwardedFrom: forwardedFrom
        )
    }
}
