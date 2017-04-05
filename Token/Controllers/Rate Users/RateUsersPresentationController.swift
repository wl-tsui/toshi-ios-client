import UIKit
import SweetUIKit

class RateUsersPresentationController: UIPresentationController {

    override func presentationTransitionWillBegin() {
        guard let rateUsersController = presentedViewController as? RateUsersController else { return }
        guard let containerView = containerView, let presentedView = presentedView else { return }

        containerView.addSubview(presentedView)
        rateUsersController.background.alpha = 0

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUsersController.background.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let rateUsersController = presentedViewController as? RateUsersController else { return }

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            rateUsersController.background.alpha = 0
        }, completion: nil)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView?.bounds ?? .zero
    }
}
