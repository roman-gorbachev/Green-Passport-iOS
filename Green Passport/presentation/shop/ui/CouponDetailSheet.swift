import SwiftUI

extension View {
    func couponDetailSheet(
        item: Binding<CouponItem?>,
        container: AppDIContainer,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        return sheet(item: item, onDismiss: onDismiss) { selected in
            CouponDetailRoute(item: selected, container: container)
                .presentationDetents([.large])
                .presentationBackground(Palette.screenBackground)
                .presentationDragIndicator(.visible)
        }
    }
}
