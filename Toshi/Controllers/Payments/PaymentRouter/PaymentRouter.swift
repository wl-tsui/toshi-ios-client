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

protocol PaymentRouterDelegate: class {
    func paymentRouterDidCancel(paymentRouter: PaymentRouter)
    func paymentRouterDidSucceedPayment(paymentRouter: PaymentRouter)
}

class PaymentRouter {
    weak var delegate: PaymentRouterDelegate?

    private var paymentViewModel: PaymentViewModel

    init(withAddress address: String? = nil, andValue value: NSDecimalNumber? = nil) {
      self.paymentViewModel = PaymentViewModel(recipientAddress: address, value: value)
    }

    // I purposefully created this method so the caller is aware that this object will present a VC
    func present() {
        //here should be decided what controller should be presented first
        guard let value = paymentViewModel.value else {
            presentPaymentValueController()
            return
        }

        guard let address =  paymentViewModel.recipientAddress else {
            presentRecipientAddressController(withValue: value)
            return
        }

        presentPaymentConfirmationController(withValue: value, andRecipientAddress: address)
    }

    private func presentPaymentValueController() {
        let paymentValueController = PaymentController(withPaymentType: .send, continueOption: .next)
        paymentValueController.delegate = self

        presentViewControllerOnNavigator(paymentValueController)
    }

    private func presentRecipientAddressController(withValue value: NSDecimalNumber) {
        let addressController = PaymentAddressController(with: value)
//        addressController.delegate = self

        presentViewControllerOnNavigator(addressController)
    }

    private func presentPaymentConfirmationController(withValue value: NSDecimalNumber, andRecipientAddress address: String) {
        let paymentConfirmationController = PaymentConfirmationViewController(withValue: value, andRecipientAddress: address)
//        paymentConfirmationController.delegate = self

        presentViewControllerOnNavigator(paymentConfirmationController)
    }

    private func presentViewControllerOnNavigator(_ controller: UIViewController) {

        if let paymentNavigationController = Navigator.topViewController as? PaymentNavigationController {
            paymentNavigationController.pushViewController(controller, animated: true)
        } else {
            let navigationController = PaymentNavigationController(rootViewController: controller)
            Navigator.presentModally(navigationController)
        }
    }
}

extension PaymentRouter: PaymentControllerDelegate {
    func paymentControllerFinished(with valueInWei: NSDecimalNumber?, for controller: PaymentController) {
        guard let value = valueInWei else { return }
        paymentViewModel.setValue(value)
        present()
    }

}
