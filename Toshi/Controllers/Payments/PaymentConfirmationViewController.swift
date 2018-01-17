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

    private lazy var avatarImageView = AvatarImageView()

    private lazy var recipientLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = "Recipient"

        return view
    }()

    private lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredDisplayName()
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = "Marijn"

        return view
    }()

    private lazy var fetchingNetworkFeesLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = "Fetching estimated network fees..."

        return view
    }()

    private lazy var receiptView: ReceiptView = {
        let view = ReceiptView()

        view.isHidden = true

        return view
    }()

    private lazy var payButton: ActionButton = {
        let button = ActionButton(margin: 15)
        button.title = "Pay"
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)

        return button
    }()

    private lazy var balanceLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontForContentSizeCategory = true

        view.text = "Your balance is ...."

        return view
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
            self?.payButton.title = message
        }
    }

    private func addSubviewsAndConstraints() {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.delaysContentTouches = false
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }

        view.addSubview(scrollView)
        scrollView.edges(to: layoutGuide())

        let containerView = UIView()
        scrollView.addSubview(containerView)

        containerView.edgesToSuperview()
        containerView.width(to: scrollView)

        let confirmPaymentStackView = UIStackView()
        confirmPaymentStackView.addBackground(with: Theme.viewBackgroundColor)
        confirmPaymentStackView.axis = .vertical
        confirmPaymentStackView.alignment = .center

        containerView.addSubview(confirmPaymentStackView)
        confirmPaymentStackView.leftToSuperview()
        confirmPaymentStackView.rightToSuperview()
        confirmPaymentStackView.top(to: layoutGuide())

        // Profile Stack View
        let profileDetailsStackView = UIStackView()
        profileDetailsStackView.addBackground(with: Theme.viewBackgroundColor)
        profileDetailsStackView.axis = .vertical
        profileDetailsStackView.alignment = .center

        confirmPaymentStackView.addWithCenterConstraint(view: profileDetailsStackView)

        let margin = CGFloat.defaultMargin

        profileDetailsStackView.addWithCenterConstraint(view: avatarImageView)
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        profileDetailsStackView.addSpacing(margin, after: avatarImageView)
        profileDetailsStackView.addSpacing(.giantInterItemSpacing, after: lastAddedView)

        profileDetailsStackView.addWithDefaultConstraints(view: recipientLabel)
        profileDetailsStackView.addWithDefaultConstraints(view: nameLabel)

        // Receipt Stack View
        let receiptStackView = UIStackView()
        receiptStackView.addBackground(with: Theme.viewBackgroundColor)
        receiptStackView.axis = .vertical
        receiptStackView.alignment = .center

        confirmPaymentStackView.addWithCenterConstraint(view: receiptStackView)
        receiptStackView.addWithDefaultConstraints(view: fetchingNetworkFeesLabel)
        receiptStackView.addWithDefaultConstraints(view: receiptView)

        confirmPaymentStackView.addWithDefaultConstraints(view: payButton, margin: margin)
        confirmPaymentStackView.addWithCenterConstraint(view: balanceLabel)

    }

    @objc func didTapPayButton() {
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
