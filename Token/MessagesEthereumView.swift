import UIKit
import SweetUIKit

protocol MessagesEthereumViewDelegate: class {
    func messagesEthereumView(_ messagesEthereumView: MessagesEthereumView, didPressRequestButton button: UIButton)
    func messagesEthereumView(_ messagesEthereumView: MessagesEthereumView, didPressPayButton button: UIButton)
}

class MessagesEthereumView: UIView {
    weak var delegate: MessagesEthereumViewDelegate?

    static let height = CGFloat(56)

    lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.ethereumBalanceLabelColor
        label.font = Theme.ethereumBalanceLabelFont

        let text = "$20.00 USD · 0.456 ETH"
        let coloredPart = "· 0.456 ETH"
        let range = (text as NSString).range(of: coloredPart)
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.ethereumBalanceLabelLightColor, range: range)
        label.attributedText = attributedString

        return label
    }()

    static func button() -> UIButton {
        let button = UIButton(withAutoLayout: true)
        button.setTitleColor(Theme.ethereumBalanceCallToActionColor, for: .normal)
        button.titleLabel?.font = Theme.ethereumBalanceCallToActionFont

        return button
    }

    lazy var requestButton: UIButton = {
        let button = MessagesEthereumView.button()
        button.setTitle("Request", for: .normal)
        button.addTarget(self, action: #selector(request(button:)), for: .touchUpInside)

        return button
    }()

    lazy var payButton: UIButton = {
        let button = MessagesEthereumView.button()
        button.setTitle("Pay", for: .normal)
        button.addTarget(self, action: #selector(pay(button:)), for: .touchUpInside)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.white
        self.addSubview(self.balanceLabel)
        self.addSubview(self.requestButton)
        self.addSubview(self.payButton)

        let margin = CGFloat(10)
        self.balanceLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.balanceLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin).isActive = true
        self.balanceLabel.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        let buttonWidth = CGFloat(70)
        self.requestButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.requestButton.leftAnchor.constraint(equalTo: self.balanceLabel.rightAnchor).isActive = true
        self.requestButton.rightAnchor.constraint(equalTo: self.payButton.leftAnchor).isActive = true
        self.requestButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        self.requestButton.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        self.payButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.payButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.payButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        self.payButton.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func request(button: UIButton) {
        self.delegate?.messagesEthereumView(self, didPressRequestButton: button)
    }

    func pay(button: UIButton) {
        self.delegate?.messagesEthereumView(self, didPressPayButton: button)
    }
}
