import AuthenticationServices
import SwiftUI

struct AuthScreen: View {
    private static let isAppleSignInAvailable = false
    private static let mascotSize: CGFloat = 120
    private static let registerStepCount = 5
    private static let socialButtonHeight: CGFloat = 50
    private static let googleLogoSize: CGFloat = 18

    let uiState: AuthUiState
    let onAction: (AuthUserAction) -> Void
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, Error>) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAppleComingSoonPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                header
                fields
                if let failure = uiState.failure {
                    Text(failure.message)
                        .font(.footnote)
                        .foregroundStyle(Palette.error)
                        .multilineTextAlignment(.center)
                }
                AppButton(
                    title: uiState.mode == .signIn ? .logIn : .next,
                    isLoading: uiState.isLoading
                ) {
                    onAction(.submit)
                }
                Text(.or)
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                socialButtons
                footer
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.large)
            .animation(.snappy, value: uiState.mode)
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissesKeyboardOnBackgroundTap()
        .background(Palette.screenBackground)
    }

    private var header: some View {
        VStack(spacing: Spacing.medium) {
            if uiState.mode == .register {
                StepIndicator(stepCount: Self.registerStepCount, currentStep: 0)
            }
            MascotImage(size: Self.mascotSize)
            Text(uiState.mode == .signIn ? .signIn : .createAccount)
                .font(.largeTitle.bold())
        }
    }

    private var fields: some View {
        VStack(spacing: Spacing.small) {
            InputField(
                title: .email,
                text: binding(\.email) { return .emailChanged($0) },
                error: uiState.isEmailInvalid ? .enterValidEmail : nil,
                contentType: .emailAddress,
                keyboard: .emailAddress
            )
            InputField(
                title: .password,
                text: binding(\.password) { return .passwordChanged($0) },
                error: uiState.isPasswordTooShort ? .passwordAtLeast6Characters : nil,
                isSecure: true,
                contentType: uiState.mode == .signIn ? .password : .newPassword
            )
            if uiState.mode == .register {
                InputField(
                    title: .repeatPassword,
                    text: binding(\.confirmPassword) { return .confirmPasswordChanged($0) },
                    error: uiState.isPasswordMismatch ? .passwordsDoNotMatch : nil,
                    isSecure: true,
                    contentType: .newPassword
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var socialButtons: some View {
        VStack(spacing: Spacing.small) {
            appleButton
            Button {
                onAction(.continueWithGoogle)
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(.googleLogo)
                        .resizable()
                        .frame(width: Self.googleLogoSize, height: Self.googleLogoSize)
                    Text(.continueWithGoogle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: Self.socialButtonHeight)
                .foregroundStyle(Color.primary)
                .background(Palette.cardBackground, in: .capsule)
                .overlay {
                    Capsule().strokeBorder(Color(.separator))
                }
            }
            .buttonStyle(.plain)
            .disabled(uiState.isLoading)
        }
    }

    @ViewBuilder
    private var appleButton: some View {
        if Self.isAppleSignInAvailable {
            SignInWithAppleButton(.continue, onRequest: onAppleRequest, onCompletion: onAppleCompletion)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: Self.socialButtonHeight)
                .clipShape(.capsule)
                .disabled(uiState.isLoading)
        } else {
            Button {
                isAppleComingSoonPresented = true
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "apple.logo")
                    Text(.continueWithApple)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: Self.socialButtonHeight)
                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                .background(colorScheme == .dark ? Color.white : Color.black, in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(uiState.isLoading)
            .alert(Text(.appleSignInComingSoonMsg), isPresented: $isAppleComingSoonPresented) {
                Button(role: .cancel) {
                    isAppleComingSoonPresented = false
                } label: {
                    Text(.close)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.xSmall) {
            Button {
                onAction(.toggleMode)
            } label: {
                Text(uiState.mode == .signIn ? .noAccountCreateOne : .alreadyHaveAccountSignIn)
                    .font(.subheadline.weight(.medium))
            }
            if uiState.mode == .signIn {
                Button {
                    onAction(.continueAnonymously)
                } label: {
                    Text(.continueWithoutAccount)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
        .disabled(uiState.isLoading)
    }

    private func binding(
        _ keyPath: KeyPath<AuthUiState, String>,
        action: @escaping (String) -> AuthUserAction
    ) -> Binding<String> {
        return Binding(
            get: { return uiState[keyPath: keyPath] },
            set: { onAction(action($0)) }
        )
    }
}

#Preview {
    AuthScreen(
        uiState: AuthUiState(),
        onAction: { _ in },
        onAppleRequest: { _ in },
        onAppleCompletion: { _ in }
    )
}
