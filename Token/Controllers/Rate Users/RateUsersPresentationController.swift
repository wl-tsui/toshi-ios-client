import UIKit
import SweetUIKit

class RateUsersPresentationController: UIPresentationController {

    override func presentationTransitionWillBegin() {
        guard let rateUsersController = self.presentedViewController as? RateUsersController else { return }
        guard let containerView = self.containerView, let presentedView = self.presentedView else { return }

        containerView.addSubview(presentedView)
        rateUsersController.background.alpha = 0

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUsersController.background.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let rateUsersController = self.presentedViewController as? RateUsersController else { return }

        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUsersController.background.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return self.containerView?.bounds ?? .zero
    }
}
