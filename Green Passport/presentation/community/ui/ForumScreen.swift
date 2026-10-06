import SwiftUI

struct ForumScreen: View {
    private static let avatarSize: CGFloat = 36

    let uiState: ForumUiState
    @Binding var draft: String
    let onPost: () -> Void
    let onReport: (ForumPost, ReportReason) -> Void
    let onMessageAction: (MessageAction, MessageTarget) -> Void
    let onCancelComposerMode: () -> Void
    let isMuted: Bool
    let onToggleMute: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List(uiState.posts) { post in
                postRow(post) { messageId in
                    withAnimation {
                        proxy.scrollTo(messageId, anchor: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if uiState.isLoading {
                StateView(kind: .loading)
            } else if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
            } else if uiState.posts.isEmpty {
                StateView(kind: .empty(message: .forumEmpty))
            }
        }
        .safeAreaInset(edge: .bottom) {
            MessageComposer(
                draft: $draft,
                placeholder: .forumDraftLabel,
                isSending: uiState.isPosting,
                errorMessage: composerError,
                onSend: onPost,
                banner: uiState.composerMode.banner,
                onCancelBanner: onCancelComposerMode
            )
        }
        .navigationTitle(Text(.communityForumTitle))
        .toolbar {
            if uiState.currentUserId != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onToggleMute) {
                        if isMuted {
                            Label(String(localized: .unmuteChat), systemImage: "bell.slash")
                        } else {
                            Label(String(localized: .muteChat), systemImage: "bell")
                        }
                    }
                }
            }
        }
    }

    private var composerError: LocalizedStringResource? {
        if uiState.isTextRejected {
            return .textContainsBannedWords
        }
        if uiState.isSendFailed {
            return .messageNotSentMsg
        }
        return nil
    }

    private func postRow(_ post: ForumPost, onQuoteTap: @escaping (String) -> Void) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                ProfileAvatar(style: post.authorAvatar ?? .lime, size: Self.avatarSize)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(post.authorName ?? String(localized: .guest))
                        .font(.subheadline.weight(.semibold))
                    Text(timestamp(post))
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer()
                reportControl(post)
            }
            MessageContentView(
                text: post.text,
                isDeleted: post.isDeleted,
                replyTo: post.replyTo,
                forwardedFrom: post.forwardedFrom,
                onQuoteTap: onQuoteTap
            )
        }
        .padding(.vertical, Spacing.xxSmall)
        .messageActions(target: post.target(currentUserId: uiState.currentUserId), onAction: onMessageAction)
    }

    private func timestamp(_ post: ForumPost) -> String {
        let date = post.createdAt.formatted(date: .abbreviated, time: .shortened)
        guard post.isEdited, !post.isDeleted else {
            return date
        }
        return String(localized: .dateTime(date, String(localized: .edited)))
    }

    @ViewBuilder
    private func reportControl(_ post: ForumPost) -> some View {
        if post.authorId != uiState.currentUserId && uiState.currentUserId != nil && !post.isDeleted {
            if uiState.reportedPostIds.contains(post.id) {
                Text(.reportSent)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                Menu {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button {
                            onReport(post, reason)
                        } label: {
                            Text(reason.title)
                        }
                    }
                } label: {
                    Image(systemName: "flag")
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityLabel(Text(.report))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForumScreen(
            uiState: ForumUiState(
                posts: [ForumPost(id: "1", authorId: "2", authorName: "Аня", authorAvatar: .berry, text: "Кто идёт на субботник?", createdAt: .now, isHidden: false, reportCount: 0)],
                isLoading: false,
                currentUserId: "1"
            ),
            draft: .constant(""),
            onPost: {},
            onReport: { _, _ in },
            onMessageAction: { _, _ in },
            onCancelComposerMode: {},
            isMuted: true,
            onToggleMute: {},
            onRetry: {}
        )
    }
}
