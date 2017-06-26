// Copyright (c) 2017 Token Browser, Inc
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

import Foundation
import UIKit

typealias ActionHandler = ((UIAlertAction) -> Swift.Void)

protocol PaymentPresentable: class {
    func displayPaymentConfirmation(userInfo: UserInfo, parameters: [String: Any])

    func paymentFailed(with error: Error?, result: [String: Any])

    func presentSuccessAlert(with actionBlock: ((UIAlertAction) -> Swift.Void)?)

    func paymentDeclined()
    func paymentApproved(with parameters: [String: Any], userInfo: UserInfo)
}

extension PaymentPresentable where Self: UIViewController {

    /// Displays payment confirmation for given user info and parameters
    ///
    /// - Parameters:
    ///   - userInfo:
    ///   - parameters: include from, to, and value in wei fields

    func displayPaymentConfirmation(userInfo: UserInfo, parameters: [String: Any]) {

        guard let valueString = parameters["value"] as? String else { return }

        let paymentConfirmationController = PaymentConfirmationController(userInfo: userInfo, value: NSDecimalNumber(hexadecimalString: valueString))

        let declineIcon = UIImage(named: "cross")
        let declineAction = Action(title: "Decline", titleColor: UIColor(white: 0.5, alpha: 1.0), icon: declineIcon) { _ in
            paymentConfirmationController.dismiss(animated: true, completion: nil)
            self.paymentDeclined()
        }

        let approveIcon = UIImage(named: "check")
        let approveAction = Action(title: "Approve", titleColor: Theme.tintColor, icon: approveIcon) { _ in

            paymentConfirmationController.dismiss(animated: true, completion: nil)
            self.paymentApproved(with: parameters, userInfo: userInfo)
        }

        paymentConfirmationController.actions = [declineAction, approveAction]

        self.present(paymentConfirmationController, animated: true)
    }

    func paymentFailed(with _: Error?, result _: [String: Any]) {}

    func presentPaymentError(error: Error?, json: [String: Any]) {
        let message = json["message"] as? String
        let alert = UIAlertController(title: "Error completing transaction", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default) { _ in
            self.paymentFailed(with: error, result: json)
        }

        alert.addAction(okAction)

        self.present(alert, animated: true, completion: nil)
    }

    func presentSuccessAlert(with actionBlock: ((UIAlertAction) -> Swift.Void)?) {
        let alertControlelr = UIAlertController.init(title: "Done", message: "Payment succeeded", preferredStyle: .alert)
        let action = UIAlertAction.init(title: "OK", style: .default) { action in
            actionBlock?(action)
        }

        alertControlelr.addAction(action)

        self.present(alertControlelr, animated: true, completion: nil)
    }
}
