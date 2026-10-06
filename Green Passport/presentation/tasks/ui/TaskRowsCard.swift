import SwiftUI

struct TaskRowsCard: View {
    private static let mascotSize: CGFloat = 34

    let tasks: [EcoTask]
    let onTask: (EcoTask) -> Void

    var body: some View {
        VStack(spacing: Spacing.small) {
            ForEach(tasks) { task in
                Button {
                    onTask(task)
                } label: {
                    ListRow(title: task.title, subtitle: task.city.isEmpty ? nil : CityName.title(task.city)) {
                        MascotImage(size: Self.mascotSize)
                    } trailing: {
                        PointsBadge(points: task.rewardPoints)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.tertiaryText)
                    }
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.xSmall)
                    .background(Palette.cardBackground, in: .rect(cornerRadius: CornerRadius.large, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    TaskRowsCard(tasks: EcoTask.placeholders(count: 3), onTask: { _ in })
        .padding()
        .background(Palette.screenBackground)
}
