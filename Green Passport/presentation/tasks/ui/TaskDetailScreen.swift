import SwiftUI

struct TaskDetailScreen: View {
    private static let mascotSize: CGFloat = 64
    private static let imageAspectRatio: CGFloat = 1.5
    private static let unsafePhotoReason = "unsafe_photo"
    private static let invalidPhotoReason = "invalid_photo"

    let uiState: TaskDetailUiState
    let onConfirm: () -> Void
    let onToggleFavorite: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
            } else if let task = uiState.task, !uiState.isLoading {
                content(task: task)
            } else {
                StateView(kind: .loading)
            }
        }
        .background(Palette.screenBackground)
        .sensoryFeedback(.success, trigger: uiState.isCompleted) { _, isCompleted in
            return isCompleted
        }
    }

    private func content(task: EcoTask) -> some View {
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    if let imageUrl = task.imageUrl.flatMap(URL.init(string:)) {
                        Color.clear
                            .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
                            .overlay {
                                RemoteImage(url: imageUrl)
                            }
                            .clipShape(.rect(cornerRadius: CornerRadius.large, style: .continuous))
                    }
                    HStack(alignment: .top, spacing: Spacing.medium) {
                        MascotImage(size: Self.mascotSize)
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(task.title)
                                .font(.title2.bold())
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: Spacing.xSmall) {
                                    PointsBadge(points: task.rewardPoints)
                                    verificationLabel(task: task)
                                }
                                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                    PointsBadge(points: task.rewardPoints)
                                    verificationLabel(task: task)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        FavoriteButton(isFavorite: uiState.isFavorite, action: onToggleFavorite)
                            .font(.title2)
                    }
                    Text(task.description)
                        .font(.body)
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.xLarge)
                .padding(.bottom, Spacing.small)
                .reportsSheetContentHeight()
            }
            .scrollBounceBehavior(.basedOnSize)
            confirmation(task: task)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.medium)
                .reportsSheetContentHeight()
        }
    }

    private func verificationLabel(task: EcoTask) -> some View {
        return Label {
            Text(task.verification.title)
        } icon: {
            Image(systemName: task.verification.systemImage)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Palette.secondaryText)
        .lineLimit(1)
    }

    @ViewBuilder
    private func confirmation(task: EcoTask) -> some View {
        VStack(spacing: Spacing.small) {
            if uiState.isCompleted {
                statusText(uiState.earnedPoints.map { return .taskDonePointsEarned($0) } ?? .taskDetailCompletedLabel, color: Palette.forest)
                if uiState.streakBonus > 0 {
                    Text(.streakBonusMsg(uiState.streakBonus))
                        .font(.subheadline)
                        .foregroundStyle(Palette.forest)
                }
            } else if task.verification == .photo && uiState.submission?.status == .pending {
                statusText(.photoUnderReviewMsg, color: Palette.forest)
            } else {
                if task.verification == .photo, let submission = uiState.submission, submission.status == .rejected {
                    statusText(.photoRejected(rejectionReason(submission.rejectionReason)), color: Palette.error)
                }
                Text(task.verification.hint)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                AppButton(
                    title: task.verification.confirmTitle(submissionStatus: uiState.submission?.status),
                    isLoading: uiState.isSubmitting,
                    action: onConfirm
                )
            }
            if let failure = uiState.failure {
                Text(failure.message)
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.snappy, value: uiState.isCompleted)
    }

    private func statusText(_ text: LocalizedStringResource, color: Color) -> some View {
        return Text(text)
            .font(.headline)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
    }

    private func rejectionReason(_ reason: String?) -> String {
        switch reason {
        case nil, "":
            return String(localized: .noReasonGiven)
        case Self.unsafePhotoReason, Self.invalidPhotoReason:
            return String(localized: .photoFailedAutomaticCheckMsg)
        default:
            return reason ?? ""
        }
    }
}

#Preview {
    TaskDetailScreen(
        uiState: TaskDetailUiState(task: EcoTask.placeholders(count: 1).first, isLoading: false),
        onConfirm: {},
        onToggleFavorite: {},
        onRetry: {}
    )
}
