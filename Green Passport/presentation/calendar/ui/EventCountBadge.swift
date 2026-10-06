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
        return CapsuleRow(capsules: capsules, spacing: Self.capsuleSpacing)
    }

    private static func capsule(count: Int, color: Color) -> UILabel {
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
        return label
    }
}

private final class CapsuleRow: UIView {
    private let capsules: [UILabel]
    private let spacing: CGFloat
    private let contentSize: CGSize

    init(capsules: [UILabel], spacing: CGFloat) {
        self.capsules = capsules
        self.spacing = spacing
        let width = capsules.map(\.frame.width).reduce(0, +) + spacing * CGFloat(max(0, capsules.count - 1))
        let height = capsules.map(\.frame.height).max() ?? 0
        contentSize = CGSize(width: width, height: height)
        super.init(frame: CGRect(origin: .zero, size: contentSize))
        capsules.forEach(addSubview)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var intrinsicContentSize: CGSize {
        return contentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return contentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var x = bounds.midX - contentSize.width / 2
        for capsule in capsules {
            capsule.frame.origin = CGPoint(x: x, y: bounds.midY - capsule.frame.height / 2)
            x += capsule.frame.width + spacing
        }
    }
}
