import SwiftUI

struct ProfileSetupScreen: View {
    private static let topBarButtonSize: CGFloat = 44
    private static let avatarPreviewSize: CGFloat = 140
    private static let avatarOptionSize: CGFloat = 56
    private static let selectionRingWidth: CGFloat = 3
    private static let selectionRingInset: CGFloat = -5

    let uiState: ProfileSetupUiState
    let isEditing: Bool
    let onAction: (ProfileSetupUserAction) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(uiState.step.title)
                            .font(.largeTitle.bold())
                        Text(uiState.step.subtitle)
                            .font(.body)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    stepContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.medium)
                .id(uiState.step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnBackgroundTap()
            bottomBar
        }
        .animation(.snappy, value: uiState.step)
        .background(Palette.screenBackground)
    }

    private var topBar: some View {
        HStack {
            if uiState.step != .name {
                circleButton(systemImage: "chevron.left", label: .back) {
                    onAction(.back)
                }
            } else if isEditing {
                circleButton(systemImage: "xmark", label: .back, action: onClose)
            } else {
                Color.clear.frame(width: Self.topBarButtonSize, height: Self.topBarButtonSize)
            }
            Spacer()
            StepIndicator(stepCount: ProfileSetupStep.totalSteps, currentStep: uiState.step.rawValue + 1)
            Spacer()
            if uiState.step == .name && !isEditing {
                Button {
                    onAction(.signOut)
                } label: {
                    Text(.exit)
                        .font(.subheadline.weight(.medium))
                }
                .frame(minWidth: Self.topBarButtonSize, minHeight: Self.topBarButtonSize)
            } else {
                Color.clear.frame(width: Self.topBarButtonSize, height: Self.topBarButtonSize)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.top, Spacing.xSmall)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch uiState.step {
        case .name:
            VStack(spacing: Spacing.small) {
                InputField(
                    title: .firstName,
                    text: Binding(get: { return uiState.firstName }, set: { onAction(.firstNameChanged($0)) }),
                    error: uiState.firstNameError?.message,
                    contentType: .givenName
                )
                InputField(
                    title: .lastName,
                    text: Binding(get: { return uiState.lastName }, set: { onAction(.lastNameChanged($0)) }),
                    error: uiState.lastNameError?.message,
                    contentType: .familyName
                )
            }
        case .city:
            VStack(alignment: .leading, spacing: Spacing.small) {
                FlowLayout {
                    ForEach(SupportedCities.all, id: \.self) { city in
                        ChoiceCapsule(title: CityName.title(city), isSelected: uiState.city == city) {
                            onAction(.citySelected(city))
                        }
                    }
                }
                if uiState.isCityMissing {
                    errorText(.chooseCity)
                }
            }
        case .interests:
            VStack(alignment: .leading, spacing: Spacing.small) {
                FlowLayout {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        ChoiceCapsule(
                            title: String(localized: category.interestTitle),
                            isSelected: uiState.interests.contains(category)
                        ) {
                            onAction(.interestToggled(category))
                        }
                    }
                }
                if uiState.isInterestsMissing {
                    errorText(.chooseAtLeastOne)
                }
            }
        case .avatar:
            VStack(spacing: Spacing.xLarge) {
                ProfileAvatar(style: uiState.avatar, size: Self.avatarPreviewSize)
                    .animation(.snappy, value: uiState.avatar)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: AvatarStyle.allCases.count / 2), spacing: Spacing.large) {
                    ForEach(AvatarStyle.allCases, id: \.self) { style in
                        Button {
                            onAction(.avatarSelected(style))
                        } label: {
                            ProfileAvatar(style: style, size: Self.avatarOptionSize)
                                .overlay {
                                    Circle()
                                        .inset(by: Self.selectionRingInset)
                                        .strokeBorder(
                                            uiState.avatar == style ? Palette.forest : .clear,
                                            lineWidth: Self.selectionRingWidth
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(uiState.avatar == style ? .isSelected : [])
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .sensoryFeedback(.selection, trigger: uiState.avatar)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: Spacing.small) {
            if uiState.hasSaveError {
                errorText(.couldNotSaveProfileMsg)
                    .multilineTextAlignment(.center)
            }
            AppButton(title: primaryTitle, isLoading: uiState.isSaving) {
                onAction(.next)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.medium)
    }

    private var primaryTitle: LocalizedStringResource {
        guard uiState.step == .avatar else {
            return .next
        }
        return isEditing ? .save : .done
    }

    private func errorText(_ text: LocalizedStringResource) -> some View {
        return Text(text)
            .font(.footnote)
            .foregroundStyle(Palette.error)
    }

    private func circleButton(
        systemImage: String,
        label: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: Self.topBarButtonSize, height: Self.topBarButtonSize)
        }
        .adaptiveGlassButtonStyle()
        .buttonBorderShape(.circle)
        .accessibilityLabel(Text(label))
    }
}

#Preview {
    ProfileSetupScreen(
        uiState: ProfileSetupUiState(step: .city, city: "Минск"),
        isEditing: false,
        onAction: { _ in },
        onClose: {}
    )
}
