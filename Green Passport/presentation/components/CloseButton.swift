import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text(.close))
        }
    }
}

#Preview {
    CloseButton {}
}
