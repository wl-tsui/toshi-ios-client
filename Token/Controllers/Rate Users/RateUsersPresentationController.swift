import UIKit
import SweetUIKit

class RateUserPresentationController: UIPresentationController {

    override func presentationTransitionWillBegin() {
        guard let rateUserController = self.presentedViewController as? RateUserController else { return }
        guard let containerView = self.containerView, let presentedView = self.presentedView else { return }

        containerView.addSubview(presentedView)
        rateUserController.background.alpha = 0

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUserController.background.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let rateUserController = self.presentedViewController as? RateUserController else { return }

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUserController.background.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return self.containerView?.bounds ?? .zero
    }
}
