import SwiftUI

struct ModerationScreen: View {
    private static let photoHeight: CGFloat = 200
    private static let avatarSize: CGFloat = 32

    let uiState: ModerationUiState
    let onReview: (SubmissionItem, Bool, String?) -> Void
    let onModerate: (ForumPost, ModerationAction) -> Void

    @State private var tab: ModerationTab = .photos
    @State private var postPendingDeletion: ForumPost?

    var body: some View {
        Group {
            if uiState.isLoading {
                StateView(kind: .loading)
            } else if !uiState.isModerator {
                StateView(kind: .empty(message: .moderatorsOnlyMsg))
            } else {
                content
            }
        }
        .background(Palette.screenBackground)
        .navigationTitle(Text(.moderation))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            Text(.delete),
            isPresented: Binding(get: { return postPendingDeletion != nil }, set: { if !$0 { postPendingDeletion = nil } }),
            presenting: postPendingDeletion
        ) { post in
            Button(role: .destructive) {
                onModerate(post, .delete)
            } label: {
                Text(.delete)
            }
        }
    }

    private var content: some View {
        List {
            if uiState.hasActionError {
                Text(.actionFailedMsg)
                    .foregroundStyle(Palette.error)
            }
            switch tab {
            case .photos:
                if uiState.submissions.isEmpty {
                    emptyRow(.noPhotosToReview)
                }
                ForEach(uiState.submissions) { item in
                    submissionRow(item)
                }
            case .reports:
                if uiState.flaggedPosts.isEmpty {
                    emptyRow(.noReports)
                }
                ForEach(uiState.flaggedPosts) { post in
                    postRow(post)
                }
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .top) {
            Picker(selection: $tab) {
                Text(.taskPhotosCount(uiState.submissions.count)).tag(ModerationTab.photos)
                Text(.reportsCount(uiState.flaggedPosts.count)).tag(ModerationTab.reports)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xSmall)
        }
    }

    private func emptyRow(_ text: LocalizedStringResource) -> some View {
        return Text(text)
            .foregroundStyle(Palette.secondaryText)
            .frame(maxWidth: .infinity)
    }

    private func submissionRow(_ item: SubmissionItem) -> some View {
        let isProcessing = uiState.processingIds.contains(item.id)
        return VStack(alignment: .leading, spacing: Spacing.small) {
            RemoteImage(url: item.photoUrl)
                .frame(height: Self.photoHeight)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: CornerRadius.medium, style: .continuous))
            Text(item.taskTitle)
                .font(.headline)
            Text(item.submission.userName ?? String(localized: .noName))
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
            HStack(spacing: Spacing.small) {
                Button {
                    onReview(item, true, nil)
                } label: {
                    Text(.approve)
                        .frame(maxWidth: .infinity)
                }
                .adaptiveProminentGlassButtonStyle()
                Menu {
                    ForEach(RejectionReason.allCases, id: \.self) { reason in
                        Button {
                            onReview(item, false, String(localized: reason.title))
                        } label: {
                            Text(reason.title)
                        }
                    }
                } label: {
                    Text(.reject)
                        .frame(maxWidth: .infinity)
                }
                .adaptiveGlassButtonStyle()
            }
            .disabled(isProcessing)
            .overlay {
                if isProcessing {
                    ProgressView()
                }
            }
        }
        .padding(.vertical, Spacing.xSmall)
    }

    private func postRow(_ post: ForumPost) -> some View {
        let isProcessing = uiState.processingIds.contains(post.id)
        return VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                ProfileAvatar(style: post.authorAvatar ?? .lime, size: Self.avatarSize)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(post.authorName ?? String(localized: .guest))
                        .font(.subheadline.weight(.semibold))
                    Text(post.isHidden ? .hiddenReportsCount(post.reportCount) : .visibleReportsCount(post.reportCount))
                        .font(.caption)
                        .foregroundStyle(post.isHidden ? Palette.error : Palette.secondaryText)
                }
            }
            Text(post.text)
            HStack(spacing: Spacing.small) {
                Button {
                    onModerate(post, post.isHidden ? .restore : .hide)
                } label: {
                    Text(post.isHidden ? .restore : .hide)
                        .frame(maxWidth: .infinity)
                }
                .adaptiveGlassButtonStyle()
                Button(role: .destructive) {
                    postPendingDeletion = post
                } label: {
                    Text(.delete)
                        .frame(maxWidth: .infinity)
                }
                .adaptiveGlassButtonStyle()
            }
            .disabled(isProcessing)
        }
        .padding(.vertical, Spacing.xSmall)
    }
}

#Preview {
    NavigationStack {
        ModerationScreen(uiState: ModerationUiState(isLoading: false, isModerator: true), onReview: { _, _, _ in }, onModerate: { _, _ in })
    }
}
