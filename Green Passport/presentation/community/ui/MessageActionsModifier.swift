import SwiftUI

struct MessageActionsModifier: ViewModifier {
    let target: MessageTarget
    let onAction: (MessageAction, MessageTarget) -> Void

    @State private var isDeleteConfirmationPresented = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if !target.isDeleted {
                    menuItems
                }
            }
            .confirmationDialog(Text(.delete), isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
                Button(role: .destructive) {
                    onAction(.delete, target)
                } label: {
                    Text(.delete)
                }
            } message: {
                Text(.deleteMessageConfirmMsg)
            }
    }

    @ViewBuilder
    private var menuItems: some View {
        Button {
            onAction(.reply, target)
        } label: {
            Label(String(localized: .reply), systemImage: "arrowshape.turn.up.left")
        }
        Button {
            onAction(.copy, target)
        } label: {
            Label(String(localized: .copy), systemImage: "doc.on.doc")
        }
        Button {
            onAction(.forward, target)
        } label: {
            Label(String(localized: .forward), systemImage: "arrowshape.turn.up.right")
        }
        if target.isOwn {
            Button {
                onAction(.edit, target)
            } label: {
                Label(String(localized: .edit), systemImage: "pencil")
            }
            Button(role: .destructive) {
                isDeleteConfirmationPresented = true
            } label: {
                Label(String(localized: .delete), systemImage: "trash")
            }
        }
        if target.canReport {
            Menu {
                ForEach(ReportReason.allCases, id: \.self) { reason in
                    Button {
                        onAction(.report(reason), target)
                    } label: {
                        Text(reason.title)
                    }
                }
            } label: {
                Label(String(localized: .report), systemImage: "flag")
            }
        }
    }
}

extension View {
    func messageActions(target: MessageTarget, onAction: @escaping (MessageAction, MessageTarget) -> Void) -> some View {
        return modifier(MessageActionsModifier(target: target, onAction: onAction))
    }
}
