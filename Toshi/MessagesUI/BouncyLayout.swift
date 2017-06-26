import UIKit

public class BouncyLayout: UICollectionViewFlowLayout {

    public enum BounceStyle {
        case subtle
        case regular
        case prominent

        var damping: CGFloat {
            switch self {
            case .subtle:
                return 1
            case .regular:
                return 0.75
            case .prominent:
                return 0.5
            }
        }

        var frequency: CGFloat {
            switch self {
            case .subtle:
                return 2
            case .regular:
                return 1.5
            case .prominent:
                return 1
            }
        }
    }

    var paused: Bool = false

    private var damping: CGFloat = BounceStyle.regular.damping
    private var frequency: CGFloat = BounceStyle.regular.frequency

    public convenience init(style: BounceStyle) {
        self.init()

        self.damping = style.damping
        self.frequency = style.frequency
    }

    public convenience init(damping: CGFloat, frequency: CGFloat) {
        self.init()

        self.damping = damping
        self.frequency = frequency
    }

    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)

    public override func prepare() {
        super.prepare()

        guard let view = self.collectionView, let attributes = super.layoutAttributesForElements(in: view.bounds)?.flatMap({ $0.copy() as? UICollectionViewLayoutAttributes }) else { return }

        self.oldBehaviors(for: attributes).forEach { animator.removeBehavior($0) }
        self.newBehaviors(for: attributes).forEach { animator.addBehavior($0, damping, frequency) }
    }

    private func oldBehaviors(for attributes: [UICollectionViewLayoutAttributes]) -> [UIAttachmentBehavior] {

        let indexPaths = attributes.map { attribute in
            attribute.indexPath
        }

        let behaviors: [UIAttachmentBehavior] = self.animator.behaviors.flatMap { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let itemAttributes = behavior.items.first as? UICollectionViewLayoutAttributes else { return nil }

            return indexPaths.contains(itemAttributes.indexPath) ? nil : behavior
        }

        return behaviors
    }

    private func newBehaviors(for attributes: [UICollectionViewLayoutAttributes]) -> [UIAttachmentBehavior] {
        let indexPaths = self.animator.behaviors.flatMap { behavior in
            return ((behavior as? UIAttachmentBehavior)?.items.first as? UICollectionViewLayoutAttributes)?.indexPath
        }

        let behaviors: [UIAttachmentBehavior] = attributes.flatMap { attribute in
            if indexPaths.contains(attribute.indexPath) {
                return nil
            } else {
                return UIAttachmentBehavior(item: attribute, attachedToAnchor: attribute.center)
            }
        }

        return behaviors
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.animator.items(in: rect) as? [UICollectionViewLayoutAttributes]
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.animator.layoutAttributesForCell(at: indexPath) ?? super.layoutAttributesForItem(at: indexPath)
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let view = self.collectionView else { return false }

        self.animator.behaviors.forEach { behavior in

            guard let behavior = behavior as? UIAttachmentBehavior,
                let item = behavior.items.first else { return }

            self.update(behavior: behavior, and: item, in: view, for: newBounds)
            self.animator.updateItem(usingCurrentState: item)
        }

        return view.bounds.width != newBounds.width
    }

    private func update(behavior: UIAttachmentBehavior, and item: UIDynamicItem, in view: UICollectionView, for bounds: CGRect) {

        if self.paused { return }

        let delta = CGVector(dx: bounds.origin.x - view.bounds.origin.x, dy: bounds.origin.y - view.bounds.origin.y)
        let resistance = CGVector(dx: fabs(view.panGestureRecognizer.location(in: view).x - behavior.anchorPoint.x) / 1000, dy: fabs(view.panGestureRecognizer.location(in: view).y - behavior.anchorPoint.y) / 1000)

        item.center.y += delta.dy < 0 ? max(delta.dy, delta.dy * resistance.dy) : min(delta.dy, delta.dy * resistance.dy)
        item.center.x += delta.dx < 0 ? max(delta.dx, delta.dx * resistance.dx) : min(delta.dx, delta.dx * resistance.dx)
    }
}

extension UIDynamicAnimator {

    open func addBehavior(_ behavior: UIAttachmentBehavior, _ damping: CGFloat, _ frequency: CGFloat) {
        behavior.damping = damping
        behavior.frequency = frequency

        self.addBehavior(behavior)
    }
}
