import SwiftUI
import UIKit

private enum AppIconSwitch {
    static let darkIconName = "AppIconDark"
    static let delay: Duration = .milliseconds(900)
}

struct ThemedRoot<Content: View>: View {
    @AppStorage(UserDefaultsSettingsRepository.themeKey) private var themeRawValue = AppTheme.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .preferredColorScheme(theme.colorScheme)
            .task(id: wantsDarkIcon) {
                try? await Task.sleep(for: AppIconSwitch.delay)
                guard !Task.isCancelled else {
                    return
                }
                await applyAppIcon(dark: wantsDarkIcon)
            }
    }

    private var theme: AppTheme {
        return AppTheme(rawValue: themeRawValue) ?? .system
    }

    private var wantsDarkIcon: Bool {
        return theme == .dark || (theme == .system && systemColorScheme == .dark)
    }

    private func applyAppIcon(dark: Bool) async {
        let desiredIconName = dark ? AppIconSwitch.darkIconName : nil
        let application = UIApplication.shared
        guard application.supportsAlternateIcons, application.alternateIconName != desiredIconName else {
            return
        }
        try? await application.setAlternateIconName(desiredIconName)
    }
}
