import SwiftUI

struct CouponsScreen: View {
    private static let tileSize: CGFloat = 40

    let uiState: CouponsUiState
    @Binding var tab: CouponsTab
    let onCoupon: (CouponItem) -> Void
    let onRetry: () -> Void

    var body: some View {
        let now = Date()
        let items = uiState.items(in: tab, at: now)
        ScrollView {
            VStack(spacing: Spacing.small) {
                if uiState.isLoading {
                    StateView(kind: .loading)
                        .containerRelativeFrame(.vertical)
                } else if uiState.hasError {
                    StateView(kind: .error(retry: onRetry))
                } else if items.isEmpty {
                    StateView(kind: .empty(message: tab.emptyMessage))
                } else {
                    ForEach(items) { item in
                        card(item, now: now)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xSmall)
        }
        .background(Palette.screenBackground)
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker(selection: $tab) {
                ForEach(CouponsTab.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xSmall)
        }
        .navigationTitle(Text(.myCoupons))
        .animation(.snappy, value: tab)
    }

    private func card(_ item: CouponItem, now: Date) -> some View {
        let status = item.coupon.status(at: now)
        let isWarning = item.isExpiringSoon(at: now) || status == .expired
        return Button {
            onCoupon(item)
        } label: {
            HStack(spacing: Spacing.small) {
                SymbolTile(systemImage: "ticket.fill", style: status == .active ? .accent : .muted, size: Self.tileSize)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    if let partner = item.reward?.partnerName {
                        Text(partner)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }
                    Text(item.statusText(at: now))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isWarning ? Palette.error : Palette.forest)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .padding(Spacing.medium)
            .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CouponsScreen(uiState: CouponsUiState(isLoading: false), tab: .constant(.active), onCoupon: { _ in }, onRetry: {})
    }
}
