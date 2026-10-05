import SwiftUI

struct EventDetailScreen: View {
    private static let imageAspectRatio: CGFloat = 1.5

    let uiState: EventDetailUiState
    let onSignUp: () -> Void
    let onCheckIn: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
            } else if let event = uiState.event, !uiState.isLoading {
                content(event: event)
            } else {
                StateView(kind: .loading)
            }
        }
        .background(Palette.screenBackground)
        .sensoryFeedback(.success, trigger: uiState.isRegistered) { _, isRegistered in
            return isRegistered
        }
        .sensoryFeedback(.success, trigger: uiState.isCheckedIn) { _, isCheckedIn in
            return isCheckedIn
        }
    }

    private func content(event: EcoEvent) -> some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Color.clear
                    .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
                    .overlay {
                        RemoteImage(url: event.imageUrl.flatMap(URL.init(string:)))
                    }
                    .clipShape(.rect(cornerRadius: CornerRadius.large, style: .continuous))
                Text(event.title)
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Label {
                        Text(.dateTime(event.dateText, event.timeText))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Palette.forest)
                    }
                    Label {
                        Text(event.location)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Palette.forest)
                    }
                }
                .font(.subheadline)
                Text(event.description)
                    .font(.body)
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(Spacing.screenHorizontal)
            .reportsSheetContentHeight()
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if uiState.isCheckedIn {
                    VStack(spacing: Spacing.xxSmall) {
                        statusLabel(uiState.checkInPoints.map { return .eventPointsEarned($0) } ?? .checkedInAtEvent)
                        if uiState.streakBonus > 0 {
                            Text(.streakBonusMsg(uiState.streakBonus))
                                .font(.subheadline)
                                .foregroundStyle(Palette.forest)
                        }
                    }
                } else if uiState.isRegistered {
                    VStack(spacing: Spacing.small) {
                        statusLabel(.calendarRegisteredLabel)
                        if event.isCheckInOpen(at: Date()) {
                            AppButton(title: .checkInOnSite, isLoading: uiState.isCheckingIn, action: onCheckIn)
                        } else {
                            Text(.checkInWindowMsg)
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        if let failure = uiState.checkInFailure {
                            Text(failure.checkInMessage)
                                .font(.footnote)
                                .foregroundStyle(Palette.error)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    AppButton(
                        title: event.rewardPoints > 0 ? .signUpPoints(event.rewardPoints) : .signUp,
                        isLoading: uiState.isRegistering,
                        action: onSignUp
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.medium)
            .reportsSheetContentHeight()
        }
    }

    private func statusLabel(_ text: LocalizedStringResource) -> some View {
        return Label {
            Text(text)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
        .font(.headline)
        .foregroundStyle(Palette.forest)
    }
}

#Preview {
    EventDetailScreen(
        uiState: EventDetailUiState(
            event: EcoEvent(id: "1", title: "Субботник в парке", description: "Уборка территории", location: "Парк Горького", city: "Минск", startAt: .now, imageUrl: nil, rewardPoints: 50),
            isRegistered: true,
            isLoading: false
        ),
        onSignUp: {},
        onCheckIn: {},
        onRetry: {}
    )
}
