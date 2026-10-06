extension ChatSettings {
    func applying(_ action: ChatListAction) -> ChatSettings {
        var updated = self
        switch action {
        case .togglePin:
            updated.isPinned.toggle()
        case .toggleMute:
            updated.isMuted.toggle()
        case .toggleArchive:
            updated.isArchived.toggle()
        }
        return updated
    }
}
