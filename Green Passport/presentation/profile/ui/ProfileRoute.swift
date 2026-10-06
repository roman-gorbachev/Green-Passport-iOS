import SwiftUI

struct ProfileRoute: View {
    let container: AppDIContainer

    @Environment(TabRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: ProfileViewModel
    @State private var isEditingProfile = false

    init(container: AppDIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.buildProfileViewModel())
    }

    var body: some View {
        ProfileScreen(uiState: viewModel.uiState, languageName: AppLanguage.currentName, onAction: handle)
            .task {
                await viewModel.observe()
            }
            .onChange(of: viewModel.notificationSettingsRequests) {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openURL(url)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else {
                    return
                }
                Task {
                    await viewModel.refreshNotifications()
                }
            }
            .fullScreenCover(isPresented: $isEditingProfile) {
                ProfileSetupRoute(container: container, isEditing: true) {
                    isEditingProfile = false
                }
            }
    }

    private func handle(_ action: ProfileUserAction) {
        switch action {
        case .open(let destination):
            router.push(destination)
        case .editProfile:
            isEditingProfile = true
        case .moderation:
            router.push(.moderation)
        case .themeSelected(let theme):
            viewModel.selectTheme(theme)
        case .appIconSelected(let icon):
            viewModel.selectAppIcon(icon)
        case .notificationCategoryToggled(let category, let isEnabled):
            viewModel.toggleNotificationCategory(category, isEnabled: isEnabled)
        case .language:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        case .signOut:
            viewModel.performSignOut()
        case .retry:
            viewModel.retry()
        }
    }
}
