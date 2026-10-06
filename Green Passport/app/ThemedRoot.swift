import SwiftUI

struct ThemedRoot<Content: View>: View {
    @AppStorage(UserDefaultsSettingsRepository.themeKey) private var themeRawValue = AppTheme.system.rawValue
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .preferredColorScheme(theme.colorScheme)
    }

    private var theme: AppTheme {
        return AppTheme(rawValue: themeRawValue) ?? .system
    }
}
