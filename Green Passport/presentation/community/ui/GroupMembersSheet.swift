import SwiftUI

struct GroupMembersSheet: View {
    private static let avatarSize: CGFloat = 36

    let members: [GroupMember]
    let isLoading: Bool
    let onLoad: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(members) { member in
                Group {
                    ListRow(title: member.name ?? String(localized: .guest)) {
                        ProfileAvatar(style: member.avatar, size: Self.avatarSize)
                    } trailing: {
                        EmptyView()
                    }
                }
                .themedRowBackground()
            }
            .listStyle(.insetGrouped)
            .themedListBackground()
            .overlay {
                if isLoading && members.isEmpty {
                    StateView(kind: .loading)
                }
            }
            .navigationTitle(Text(.groupMembers))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
        }
        .presentationBackground(Palette.screenBackground)
        .task {
            await onLoad()
        }
    }
}

#Preview {
    GroupMembersSheet(
        members: [GroupMember(id: "1", name: "Аня", avatar: .berry), GroupMember(id: "2", name: nil, avatar: .sky)],
        isLoading: false,
        onLoad: {}
    )
}
