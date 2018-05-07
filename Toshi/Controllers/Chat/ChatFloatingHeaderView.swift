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
import SweetUIKit

protocol ChatFloatingHeaderViewDelegate: class {
    func messagesFloatingView(_ messagesFloatingView: ChatFloatingHeaderView, didPressRequestButton button: UIButton)
    func messagesFloatingView(_ messagesFloatingView: ChatFloatingHeaderView, didPressPayButton button: UIButton)
}

class ChatFloatingHeaderView: UIView {
    weak var delegate: ChatFloatingHeaderViewDelegate?

    static let height = CGFloat(48)

    private(set) lazy var fiatValueLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.textColor = Theme.darkTextColor
        label.font = Theme.medium(size: 15)

        return label
    }()

    private(set) lazy var dotLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.regular(size: 15)
        label.text = "·"
        label.textAlignment = .center

        return label
    }()

    private(set) lazy var ethereumValueLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.regular(size: 15)

        return label
    }()

    private static func button() -> UIButton {
        let button = UIButton(withAutoLayout: true)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.setTitleColor(Theme.lightGreyTextColor, for: .disabled)
        button.titleLabel?.font = Theme.medium(size: 15)

        return button
    }

    private(set) lazy var requestButton: UIButton = {
        let button = ChatFloatingHeaderView.button()
        button.setTitle(Localized.chat_request_payment_button_title, for: .normal)
        button.addTarget(self, action: #selector(request(button:)), for: .touchUpInside)

        return button
    }()

    private(set) lazy var payButton: UIButton = {
        let button = ChatFloatingHeaderView.button()
        button.setTitle(Localized.chat_pay_button_title, for: .normal)
        button.addTarget(self, action: #selector(pay(button:)), for: .touchUpInside)

        return button
    }()

    var balance: NSDecimalNumber? {
        didSet {
            if let balance = self.balance {
                let rate = ExchangeRateClient.exchangeRate
                fiatValueLabel.text = EthereumConverter.fiatValueStringWithCode(forWei: balance, exchangeRate: rate)
                ethereumValueLabel.text = EthereumConverter.ethereumValueString(forWei: balance)
            } else {
                fiatValueLabel.text = nil
                ethereumValueLabel.text = nil
            }
        }
    }

    private(set) lazy var separatorView = BorderView()

    var shouldShowPayButton: Bool = true {
        didSet {
            payButton.isHidden = !shouldShowPayButton
        }
    }

    var shouldShowRequestButton: Bool = true {
        didSet {
            requestButton.isHidden = !shouldShowRequestButton
        }
    }

    lazy var backgroundBlur: BlurView = {
        let view = BlurView()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundBlur)
        addSubview(fiatValueLabel)
        addSubview(dotLabel)
        addSubview(ethereumValueLabel)
        addSubview(requestButton)
        addSubview(payButton)
        addSubview(separatorView)

        backgroundBlur.edges(to: self)

        fiatValueLabel.topToSuperview()
        fiatValueLabel.bottomToSuperview()
        fiatValueLabel.leftToSuperview(offset: .mediumInterItemSpacing)

        dotLabel.leftToRight(of: fiatValueLabel)
        dotLabel.topToSuperview()
        dotLabel.bottomToSuperview()
        dotLabel.width(13)

        ethereumValueLabel.topToSuperview()
        ethereumValueLabel.bottomToSuperview()
        ethereumValueLabel.leftToRight(of: dotLabel)

        let buttonWidth = CGFloat(70)

        requestButton.topToSuperview()
        requestButton.bottomToSuperview()
        requestButton.leftToRight(of: ethereumValueLabel)
        requestButton.width(buttonWidth)

        payButton.width(buttonWidth)
        payButton.edgesToSuperview(excluding: .left)
        payButton.leftToRight(of: requestButton)

        separatorView.edgesToSuperview(excluding: .top)
        separatorView.addHeightConstraint()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func request(button: UIButton) {
        delegate?.messagesFloatingView(self, didPressRequestButton: button)
    }

    @objc func pay(button: UIButton) {
        delegate?.messagesFloatingView(self, didPressPayButton: button)
    }

    func setPaymentButtonsEnabled(_ enabled: Bool) {
        payButton.isEnabled = enabled
        requestButton.isEnabled = enabled
    }
}
