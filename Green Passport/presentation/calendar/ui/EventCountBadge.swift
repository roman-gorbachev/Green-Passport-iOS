import SwiftUI
import UIKit

enum EventCountBadge {
    private static let horizontalInset: CGFloat = 5
    private static let minimumSide: CGFloat = 16
    private static let capsuleSpacing: CGFloat = 2

    static func make(counts: DayEventCounts) -> UIView {
        let capsules = [
            (count: counts.open, color: Palette.error),
            (count: counts.registered, color: Palette.forest),
        ]
        .filter { return $0.count > 0 }
        .map { return capsule(count: $0.count, color: $0.color) }
        let stack = UIStackView(arrangedSubviews: capsules)
        stack.axis = .horizontal
        stack.spacing = Self.capsuleSpacing
        stack.alignment = .center
        return stack
    }

    private static func capsule(count: Int, color: Color) -> UIView {
        let label = UILabel()
        label.text = count.formatted()
        label.font = UIFont.preferredFont(forTextStyle: .caption2).bold()
        label.textColor = UIColor(Palette.onForest)
        label.textAlignment = .center
        label.backgroundColor = UIColor(color)
        label.layer.masksToBounds = true
        let size = label.intrinsicContentSize
        let side = max(Self.minimumSide, size.height)
        let width = max(side, size.width + Self.horizontalInset * 2)
        label.frame = CGRect(x: 0, y: 0, width: width, height: side)
        label.layer.cornerRadius = side / 2
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: width),
            label.heightAnchor.constraint(equalToConstant: side),
        ])
        return label
    }
}
