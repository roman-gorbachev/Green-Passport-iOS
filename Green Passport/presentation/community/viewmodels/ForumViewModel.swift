import Foundation
import Observation

@Observable
final class ForumViewModel {
    @ObservationIgnored private let observeSession: ObserveSessionUseCase
    @ObservationIgnored private let observeForumPosts: ObserveForumPostsUseCase
    @ObservationIgnored private let postToForum: PostToForumUseCase
    @ObservationIgnored private let reportPost: ReportPostUseCase
    @ObservationIgnored private let editMessage: EditMessageUseCase
    @ObservationIgnored private let deleteMessage: DeleteMessageUseCase

    private(set) var uiState = ForumUiState()
    private(set) var postedCount = 0
    private(set) var copiedCount = 0

    init(
        observeSession: ObserveSessionUseCase,
        observeForumPosts: ObserveForumPostsUseCase,
        postToForum: PostToForumUseCase,
        reportPost: ReportPostUseCase,
        editMessage: EditMessageUseCase,
        deleteMessage: DeleteMessageUseCase
    ) {
        self.observeSession = observeSession
        self.observeForumPosts = observeForumPosts
        self.postToForum = postToForum
        self.reportPost = reportPost
        self.editMessage = editMessage
        self.deleteMessage = deleteMessage
    }

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeUser() }
            group.addTask { await self.observePosts() }
        }
    }

    func updateDraft(_ text: String) {
        uiState.draft = text
        uiState.isTextRejected = false
        uiState.isSendFailed = false
    }

    func post() {
        let text = uiState.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let userId = uiState.currentUserId, !text.isEmpty, !uiState.isPosting else {
            return
        }
        uiState.isPosting = true
        uiState.isSendFailed = false
        let mode = uiState.composerMode
        Task {
            do {
                switch mode {
                case .new:
                    try await postToForum.execute(authorId: userId, text: text)
                case .reply(let quote):
                    try await postToForum.execute(authorId: userId, text: text, replyTo: quote)
                case .edit(let messageId):
                    try await editMessage.execute(chat: .forum, messageId: messageId, text: text)
                }
                uiState.draft = ""
                uiState.composerMode = .new
                postedCount += 1
            } catch is ContentRejectedError {
                uiState.isTextRejected = true
            } catch {
                uiState.isSendFailed = true
            }
            uiState.isPosting = false
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
        case .report(let reason):
            report(postId: target.id, reason: reason)
        case .forward:
            return
        }
    }

    func cancelComposerMode() {
        if case .edit = uiState.composerMode {
            uiState.draft = ""
        }
        uiState.composerMode = .new
    }

    func report(_ post: ForumPost, reason: ReportReason) {
        report(postId: post.id, reason: reason)
    }

    private func delete(_ target: MessageTarget) {
        if case .edit(let messageId) = uiState.composerMode, messageId == target.id {
            cancelComposerMode()
        }
        Task {
            try? await deleteMessage.execute(chat: .forum, messageId: target.id)
        }
    }

    private func report(postId: String, reason: ReportReason) {
        guard let userId = uiState.currentUserId else {
            return
        }
        Task {
            do {
                try await reportPost.execute(postId: postId, reporterId: userId, reason: reason)
                uiState.reportedPostIds.insert(postId)
            } catch {
                return
            }
        }
    }

    private func observeUser() async {
        for await session in observeSession.execute() {
            uiState.currentUserId = session?.userId
        }
    }

    private func observePosts() async {
        do {
            for try await posts in observeForumPosts.execute() {
                uiState.posts = posts
                uiState.isLoading = false
                uiState.hasError = false
            }
        } catch {
            uiState.isLoading = false
            uiState.hasError = true
        }
    }
}
