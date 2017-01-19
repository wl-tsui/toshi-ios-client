import UIKit
import SweetUIKit
import UInt256

protocol MessagesFloatingViewDelegate: class {
    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressRequestButton button: UIButton)
    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressPayButton button: UIButton)
}

class MessagesFloatingView: UIView {
    weak var delegate: MessagesFloatingViewDelegate?

    static let height = CGFloat(48)

    lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.ethereumBalanceLabelColor
        label.font = Theme.ethereumBalanceLabelFont

        return label
    }()

    static func button() -> UIButton {
        let button = UIButton(withAutoLayout: true)
        button.setTitleColor(Theme.ethereumBalanceCallToActionColor, for: .normal)
        button.titleLabel?.font = Theme.ethereumBalanceCallToActionFont

        return button
    }

    lazy var requestButton: UIButton = {
        let button = MessagesFloatingView.button()
        button.setTitle("Request", for: .normal)
        button.addTarget(self, action: #selector(request(button:)), for: .touchUpInside)

        return button
    }()

    lazy var payButton: UIButton = {
        let button = MessagesFloatingView.button()
        button.setTitle("Pay", for: .normal)
        button.addTarget(self, action: #selector(pay(button:)), for: .touchUpInside)

        return button
    }()

    var balance: UInt256? {
        didSet {
            if let balance = self.balance {
                self.balanceLabel.attributedText = User.balanceAttributedString(for: balance)
            } else {
                self.balanceLabel.attributedText = nil
            }
        }
    }

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.separatorColor

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Theme.messagesFloatingViewBackgroundColor
        self.addSubview(self.balanceLabel)
        self.addSubview(self.requestButton)
        self.addSubview(self.payButton)
        self.addSubview(self.separatorView)

        let margin = CGFloat(10)
        self.balanceLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.balanceLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.balanceLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin).isActive = true

        let buttonWidth = CGFloat(70)
        self.requestButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.requestButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.requestButton.leftAnchor.constraint(equalTo: self.balanceLabel.rightAnchor).isActive = true
        self.requestButton.rightAnchor.constraint(equalTo: self.payButton.leftAnchor).isActive = true
        self.requestButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        self.payButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.payButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.payButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.payButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        self.separatorView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        self.separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func request(button: UIButton) {
        self.delegate?.messagesFloatingView(self, didPressRequestButton: button)
    }

    func pay(button: UIButton) {
        self.delegate?.messagesFloatingView(self, didPressPayButton: button)
    }
}
