import SwiftUI

struct FeedbackScreen: View {
    private static let maxRating = 5
    private static let messageLineLimit = 3...6
    private static let supportEmail = "support@greenpassport.app"
    private static let supportPhone = "+375 (33) 555-01-01"
    private static let supportPhoneDigits = "+375335550101"

    let uiState: FeedbackUiState
    @Binding var rating: Int
    @Binding var reviewMessage: String
    @Binding var suggestionMessage: String
    let onSubmitReview: () -> Void
    let onSubmitSuggestion: () -> Void
    let onAnswerSurvey: (Int) -> Void
    let onRetry: () -> Void

    var body: some View {
        Form {
            reviewSection
            suggestionSection
            if let survey = uiState.survey {
                surveySection(survey)
            }
            supportSection
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if uiState.isLoading {
                StateView(kind: .loading)
            } else if uiState.hasError {
                StateView(kind: .error(retry: onRetry))
                    .background(Palette.screenBackground)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if uiState.earnedPoints > 0 {
                PointsBadge(points: uiState.earnedPoints)
                    .padding(.bottom, Spacing.small)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy, value: uiState.earnedPoints)
        .navigationTitle(Text(.feedback))
        .sensoryFeedback(.success, trigger: uiState.reviewSubmitted || uiState.suggestionSubmitted)
    }

    private var reviewSection: some View {
        Section {
            if uiState.reviewSubmitted {
                submittedLabel(.feedbackReviewSubmittedLabel)
            } else {
                HStack(spacing: Spacing.small) {
                    ForEach(1...Self.maxRating, id: \.self) { value in
                        Button {
                            rating = value
                        } label: {
                            Image(systemName: value <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(value <= rating ? Palette.forest : Palette.secondaryText)
                                .symbolEffect(.bounce, value: rating == value)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .frame(maxWidth: .infinity)
                .sensoryFeedback(.selection, trigger: rating)
                TextField(String(localized: .feedbackReviewMessageLabel), text: $reviewMessage, axis: .vertical)
                    .lineLimit(Self.messageLineLimit)
                submitButton(
                    title: .feedbackReviewSubmitButton,
                    isLoading: uiState.isSubmittingReview,
                    isEnabled: rating > 0,
                    action: onSubmitReview
                )
            }
        } header: {
            Text(.feedbackReviewTitle)
        } footer: {
            if uiState.isReviewRejected {
                Text(.textContainsBannedWords)
                    .foregroundStyle(Palette.error)
            }
        }
    }

    private var suggestionSection: some View {
        Section {
            if uiState.suggestionSubmitted {
                submittedLabel(.feedbackSuggestionSubmittedLabel)
            } else {
                TextField(String(localized: .feedbackSuggestionMessageLabel), text: $suggestionMessage, axis: .vertical)
                    .lineLimit(Self.messageLineLimit)
                submitButton(
                    title: .feedbackSuggestionSubmitButton,
                    isLoading: uiState.isSubmittingSuggestion,
                    isEnabled: !suggestionMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    action: onSubmitSuggestion
                )
            }
        } header: {
            Text(.feedbackSuggestionTitle)
        } footer: {
            if uiState.isSuggestionRejected {
                Text(.textContainsBannedWords)
                    .foregroundStyle(Palette.error)
            }
        }
    }

    private func surveySection(_ survey: SurveyQuestion) -> some View {
        return Section {
            Text(survey.question)
                .font(.headline)
            if uiState.hasAnsweredSurvey {
                submittedLabel(.feedbackSurveyAnsweredLabel)
            } else {
                ForEach(Array(survey.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        onAnswerSurvey(index)
                    } label: {
                        Text(option)
                    }
                    .disabled(uiState.isSubmittingSurveyAnswer)
                }
            }
        } header: {
            Text(.feedbackSurveyTitle)
        }
    }

    private var supportSection: some View {
        Section {
            if let url = URL(string: "mailto:\(Self.supportEmail)") {
                Link(destination: url) {
                    Label {
                        Text(.feedbackSupportEmailFormat(Self.supportEmail))
                    } icon: {
                        Image(systemName: "envelope.fill")
                    }
                }
            }
            if let url = URL(string: "tel:\(Self.supportPhoneDigits)") {
                Link(destination: url) {
                    Label {
                        Text(.feedbackSupportPhoneFormat(Self.supportPhone))
                    } icon: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
        } header: {
            Text(.feedbackSupportTitle)
        }
    }

    private func submittedLabel(_ text: LocalizedStringResource) -> some View {
        return Label {
            Text(text)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
        .foregroundStyle(Palette.forest)
    }

    private func submitButton(
        title: LocalizedStringResource,
        isLoading: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
            HStack {
                Text(title)
                if isLoading {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    NavigationStack {
        FeedbackScreen(
            uiState: FeedbackUiState(survey: SurveyQuestion(id: "1", question: "Как часто вы сортируете мусор?", options: ["Всегда", "Иногда"]), isLoading: false),
            rating: .constant(3),
            reviewMessage: .constant(""),
            suggestionMessage: .constant(""),
            onSubmitReview: {},
            onSubmitSuggestion: {},
            onAnswerSurvey: { _ in },
            onRetry: {}
        )
    }
}
