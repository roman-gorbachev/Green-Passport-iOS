enum MessageAction: Hashable {
    case reply
    case copy
    case forward
    case edit
    case delete
    case report(ReportReason)
}
