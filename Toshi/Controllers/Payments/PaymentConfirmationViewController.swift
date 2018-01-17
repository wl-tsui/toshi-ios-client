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

protocol PaymentConfirmationViewControllerDelegate: class {
    func paymentConfirmationViewControllerFinished(on controller: PaymentConfirmationViewController)
}

class PaymentConfirmationViewController: UIViewController {

    weak var delegate: PaymentConfirmationViewControllerDelegate?

    let paymentManager: PaymentManager

    private lazy var testButton: ActionButton = {
        let button = ActionButton(margin: 15)
        button.title = "test"
        button.addTarget(self, action: #selector(didTapTestButton), for: .touchUpInside)

        return button
    }()

    init(withValue value: NSDecimalNumber, andRecipientAddress address: String) {
        paymentManager = PaymentManager(withValue: value, andPaymentAddress: address)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()

        view.backgroundColor = Theme.viewBackgroundColor

        paymentManager.transactionSkeleton { [weak self] message in
            self?.testButton.title = message
        }
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(testButton)

        testButton.centerX(to: view)
        testButton.centerY(to: view)
        testButton.left(to: view, offset: 15)
        testButton.right(to: view, offset: -15)
    }

    @objc func didTapTestButton() {
        paymentManager.sendPayment() { [weak self] error in
            guard let weakSelf = self else { return }

            guard error == nil else {
                // handle error
                return
            }

            weakSelf.delegate?.paymentConfirmationViewControllerFinished(on: weakSelf)
        }
    }
}
