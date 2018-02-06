// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
import UIKit

class WalletQRCodeAnimationController: NSObject {

    private func animate(qrCodeStartImageView: UIImageView,
                         qrCodeEndImageView: UIImageView,
                         qrCodeImage: UIImage,
                         container: UIView,
                         context: UIViewControllerContextTransitioning) {
        let animatorQRCodeView = UIImageView(frame: qrCodeStartImageView.frame)
        animatorQRCodeView.image = qrCodeImage

        container.addSubview(animatorQRCodeView)
        qrCodeStartImageView.alpha = 0
        qrCodeEndImageView.alpha = 0

        let duration = transitionDuration(using: context)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [],
                       animations: {
                        animatorQRCodeView.frame = qrCodeEndImageView.frame
                       },
                       completion: { success in
                        qrCodeEndImageView.alpha = 1
                        animatorQRCodeView.removeFromSuperview()

                        context.completeTransition(success)

        })

    }

}

extension WalletQRCodeAnimationController: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard
            let toController = transitionContext.viewController(forKey: .to),
            let fromController = transitionContext.viewController(forKey: .from) else {
                assertionFailure("Couldn't get to or from view controller!")
                transitionContext.completeTransition(false)
                return
        }

        if
            let toQRCode = toController as? QRCodeController,
            let fromWallet = fromController as? WalletViewController {
                animateIn(qrCodeController: toQRCode,
                          from: fromWallet,
                          container: container,
                          context: transitionContext)
        } else if
            let toWallet = toController as? WalletViewController,
            let fromQRCode = fromController as? QRCodeController {
                animateOut(qrCodeController: fromQRCode,
                           to: toWalllet,
                           container: container,
                           context: transitionContext)
        } else {
            assertionFailure("Invalid view controller types for animation: To controller is \(type(of: toController)) and from controller is \(type(of: fromController))")
            transitionContext.completeTransition(false)
        }
    }

    private func animateIn(qrCodeController: QRCodeController,
                           from walletViewController: WalletViewController,
                           container: UIView,
                           context: UIViewControllerContextTransitioning) {

        

    }

    private func animateOut(qrCodeController: QRCodeController,
                            to walletViewController: WalletViewController,
                            container: UIView,
                            context: UIViewControllerContextTransitioning) {

    }
}
