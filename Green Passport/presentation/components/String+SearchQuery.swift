import Foundation

extension String {
    var isBlankSearchQuery: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func matchesSearchQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return true
        }
        return localizedStandardContains(trimmed)
    }
}
