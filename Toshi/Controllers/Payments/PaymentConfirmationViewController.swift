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

        view.text = Localized("confirmation_recipient")

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

        view.text = Localized("confirmation_fetching_estimated_network_fees")

        return view
    }()

    private lazy var receiptView: ReceiptView = {
        let view = ReceiptView()

//        view.isHidden = true

        return view
    }()

    private lazy var payButton: ActionButton = {
        let button = ActionButton(margin: 15)
        button.title = Localized("confirmation_pay")
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

        view.text = Localized("confirmation_your_balance")

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

        title = Localized("confirmation_title")

        view.backgroundColor = Theme.viewBackgroundColor

        paymentManager.transactionSkeleton { [weak self] message in
            self?.payButton.title = message
        }
    }

    private lazy var profileDetailsStackView: UIStackView = {
        let profileDetailsStackView = UIStackView()
        profileDetailsStackView.addBackground(with: Theme.viewBackgroundColor)
        profileDetailsStackView.axis = .vertical
        profileDetailsStackView.alignment = .center

        return profileDetailsStackView
    }()    

    private func addSubviewsAndConstraints() {

        let profileDetailsTopLayoutGuide = UILayoutGuide()
        let profileDetailsBottomLayoutGuide = UILayoutGuide()

        view.addLayoutGuide(profileDetailsTopLayoutGuide)
        view.addSubview(profileDetailsStackView)
        view.addLayoutGuide(profileDetailsBottomLayoutGuide)

        view.addSubview(receiptView)

        view.addSubview(payButton)
        view.addSubview(balanceLabel)

        profileDetailsTopLayoutGuide.height(10, relation: .equalOrGreater)
        profileDetailsTopLayoutGuide.top(to: layoutGuide())
        profileDetailsTopLayoutGuide.left(to: view)
        profileDetailsTopLayoutGuide.right(to: view)

        profileDetailsStackView.topToBottom(of: profileDetailsTopLayoutGuide)
        profileDetailsStackView.left(to: view)
        profileDetailsStackView.right(to: view)

        profileDetailsStackView.addWithCenterConstraint(view: avatarImageView)
        profileDetailsTopLayoutGuide.bottomToTop(of: profileDetailsStackView)
        
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        profileDetailsStackView.addSpacing(.defaultMargin, after: avatarImageView)

        profileDetailsStackView.addWithDefaultConstraints(view: recipientLabel)
        profileDetailsStackView.addWithDefaultConstraints(view: nameLabel)

        profileDetailsBottomLayoutGuide.height(to: profileDetailsTopLayoutGuide)
        profileDetailsBottomLayoutGuide.topToBottom(of: profileDetailsStackView)
        profileDetailsBottomLayoutGuide.left(to: view)
        profileDetailsBottomLayoutGuide.right(to: view)

        receiptView.topToBottom(of: profileDetailsBottomLayoutGuide)
        receiptView.left(to: view)
        receiptView.right(to: view)
        receiptView.bottomToTop(of: payButton)

        payButton.bottomToTop(of: balanceLabel, offset: -CGFloat.largeInterItemSpacing)
        payButton.left(to: view, offset: CGFloat.defaultMargin)
        payButton.right(to: view, offset: -CGFloat.defaultMargin)

        balanceLabel.bottom(to: layoutGuide(), offset: -CGFloat.largeInterItemSpacing)
        balanceLabel.left(to: view, offset: CGFloat.defaultMargin)
        balanceLabel.right(to: view, offset: -CGFloat.defaultMargin)
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
