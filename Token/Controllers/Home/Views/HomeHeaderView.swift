import UIKit
import SweetUIKit

class HomeHeaderView: UICollectionReusableView {
    lazy var balanceTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 14)
        label.textColor = Theme.greyTextColor
        label.text = "Balance"

        return label
    }()

    lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 16)
        label.textColor = Theme.greyTextColor

        return label
    }()

    lazy var actionsStackView: UIStackView = {
        let pay = HomeItemCell()
        pay.app = App(displayName: "Pay", image: #imageLiteral(resourceName: "pay-button"))

        let request = HomeItemCell()
        request.app = App(displayName: "Request", image: #imageLiteral(resourceName: "request-button"))

        let addMoney = HomeItemCell()
        addMoney.app = App(displayName: "Add Money", image: #imageLiteral(resourceName: "add-money-button"))

        let scanQR = HomeItemCell()
        scanQR.app = App(displayName: "Scan QR", image: #imageLiteral(resourceName: "scan-qr-button"))

        let stackView = UIStackView(arrangedSubviews: [pay, request, addMoney, scanQR])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Theme.viewBackgroundColor

        let sectionSeparatorView = UIView(withAutoLayout: true)
        sectionSeparatorView.backgroundColor = Theme.borderColor

        let smallSeparatorView = UIView(withAutoLayout: true)
        smallSeparatorView.backgroundColor = Theme.borderColor

        self.addSubview(sectionSeparatorView)
        self.addSubview(smallSeparatorView)
        self.addSubview(self.actionsStackView)
        self.addSubview(self.balanceTitleLabel)
        self.addSubview(self.balanceLabel)

        sectionSeparatorView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        sectionSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        sectionSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        sectionSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true

        self.actionsStackView.heightAnchor.constraint(equalToConstant: 88).isActive = true
        self.actionsStackView.bottomAnchor.constraint(equalTo: sectionSeparatorView.topAnchor).isActive = true
        self.actionsStackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.actionsStackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true

        smallSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        smallSeparatorView.bottomAnchor.constraint(equalTo: self.actionsStackView.topAnchor, constant: -25).isActive = true
        smallSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        smallSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true

        self.balanceLabel.bottomAnchor.constraint(equalTo: smallSeparatorView.topAnchor, constant: -24).isActive = true
        self.balanceLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15).isActive = true

        self.balanceTitleLabel.bottomAnchor.constraint(equalTo: smallSeparatorView.topAnchor, constant: -25).isActive = true
        self.balanceTitleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15).isActive = true
        self.balanceTitleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var balance: NSDecimalNumber? {
        didSet {
            if let balance = self.balance {
                self.balanceLabel.attributedText = EthereumConverter.balanceAttributedString(forWei: balance)
            } else {
                self.balanceLabel.attributedText = nil
            }
        }
    }
}
