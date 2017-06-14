import UIKit

class ImagesViewControllerPresentationController: UIPresentationController {

    override func presentationTransitionWillBegin() {
        guard let controller = self.presentedViewController as? ImagesViewController else { return }
        guard let containerView = self.containerView, let presentedView = self.presentedView else { return }

        containerView.addSubview(presentedView)
        controller.collectionView.alpha = 0

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            controller.collectionView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let controller = self.presentedViewController as? ImagesViewController else { return }

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            controller.collectionView.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return self.containerView?.bounds ?? .zero
    }
}
