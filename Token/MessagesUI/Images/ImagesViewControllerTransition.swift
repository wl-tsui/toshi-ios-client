import UIKit

enum ControllerTransitionOperation: Int {
    case present
    case dismiss
}

class ImagesViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let operation: ControllerTransitionOperation

    var duration: TimeInterval {
        switch self.operation {
        case .present:
            return 0.5
        case .dismiss:
            return 0.3
        }
    }

    init(operation: ControllerTransitionOperation) {
        self.operation = operation

        super.init()
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.operation {
        case .present:
            self.present(with: transitionContext)
        case .dismiss:
            self.dismiss(with: transitionContext)
        }
    }

    func present(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.to) as? ImagesViewController else { return }
        controller.collectionView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        controller.collectionView.alpha = 0
        controller.navigationBar.alpha = 0

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .easeOut, animations: {
            controller.navigationBar.alpha = 1
            controller.collectionView.alpha = 1
        }) { didComplete in
            context.completeTransition(didComplete)
        }

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: .easeOut, animations: {
            controller.collectionView.transform = .identity
        }, completion: nil)
    }

    func dismiss(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.from) as? ImagesViewController else { return }

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeIn, animations: {
            controller.collectionView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            controller.collectionView.alpha = 0
            controller.navigationBar.alpha = 0
        }) { didComplete in
            context.completeTransition(didComplete)
        }
    }
}
