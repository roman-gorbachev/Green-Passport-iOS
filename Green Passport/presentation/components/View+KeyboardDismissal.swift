import SwiftUI

extension View {
    func dismissesKeyboardOnBackgroundTap() -> some View {
        return background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture {
                    Keyboard.dismiss()
                }
        }
    }
}
