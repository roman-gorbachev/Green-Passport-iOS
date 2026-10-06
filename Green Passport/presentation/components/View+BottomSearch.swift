import SwiftUI

extension View {
    @ViewBuilder
    func bottomSearchable(text: Binding<String>, prompt: LocalizedStringResource) -> some View {
        if #available(iOS 26, *) {
            searchable(text: text, prompt: Text(prompt))
                .toolbar {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                BottomSearchField(text: text, prompt: prompt)
            }
        }
    }
}
