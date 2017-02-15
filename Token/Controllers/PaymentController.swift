import UIKit

class PaymentController: UIViewController {

    var valueInWei: NSDecimalNumber?

    lazy var currencyNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")

        return formatter
    }()

    lazy var inputNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        return formatter
    }()

    lazy var shadowTextField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.isHidden = true
        view.accessibilityTraits = UIAccessibilityTraitNotEnabled
        view.keyboardType = .decimalPad
        view.delegate = self

        return view
    }()

    lazy var currencyAmountLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textAlignment = .center
        view.minimumScaleFactor = 0.25
        view.adjustsFontSizeToFitWidth = true
        view.font = Theme.regular(size: 58)
        view.text = self.currencyNumberFormatter.string(from: 0)

        return view
    }()

    lazy var etherAmountLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textAlignment = .center
        view.minimumScaleFactor = 0.25
        view.adjustsFontSizeToFitWidth = true
        view.font = Theme.medium(size: 16)
        view.textColor = Theme.greyTextColor
        view.text = "0.0 EHT"

        return view
    }()

    lazy var toolbar: UIToolbar = {
        let view = UIToolbar(withAutoLayout: true)
        view.delegate = self
        view.barTintColor = Theme.tintColor
        view.tintColor = Theme.lightTextColor

        return view
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.viewBackgroundColor

        self.setupSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.shadowTextField.becomeFirstResponder()
    }

    func setupSubviewsAndConstraints() {
        self.view.addSubview(self.shadowTextField)
        self.view.addSubview(self.currencyAmountLabel)
        self.view.addSubview(self.etherAmountLabel)
        self.view.addSubview(self.toolbar)

        self.toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.currencyAmountLabel.set(height: 64)
        self.currencyAmountLabel.topAnchor.constraint(equalTo: self.toolbar.bottomAnchor, constant: 80).isActive = true
        self.currencyAmountLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 24).isActive = true
        self.currencyAmountLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -24).isActive = true

        self.etherAmountLabel.set(height: 34)
        self.etherAmountLabel.topAnchor.constraint(equalTo: self.currencyAmountLabel.bottomAnchor).isActive = true
        self.etherAmountLabel.leftAnchor.constraint(equalTo: self.currencyAmountLabel.leftAnchor).isActive = true
        self.etherAmountLabel.rightAnchor.constraint(equalTo: self.currencyAmountLabel.rightAnchor).isActive = true
    }
}

extension PaymentController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        defer {
            guard let currencyString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else { fatalError("!") }
            if let currencyValue = self.inputNumberFormatter.number(from: currencyString) {
                let etherValue = currencyValue.decimalValue / EthereumAPIClient.shared.exchangeRate
                let ether = NSDecimalNumber(decimal: etherValue).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)

                self.valueInWei = ether.multiplying(byPowerOf10: User.weisToEtherPowerOf10Constant)
                self.etherAmountLabel.text = User.ethereumValueString(forEther: ether)
            } else {
                self.etherAmountLabel.text = "0.0 EHT"
            }
        }

        guard let newValue = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return true
        }

        guard let number = self.inputNumberFormatter.number(from: newValue) else {
            self.currencyAmountLabel.text = self.currencyNumberFormatter.string(from: 0)

            return true
        }

        /// For NSNumber's stringValue, the decimal separator is always a `.`.
        // stringValue just calls description(withLocale:) passing nil, so it defaults to `en_US`.
        let components = number.stringValue.components(separatedBy: ".")
        if components.count == 2, let decimalPlaces = components.last?.length, decimalPlaces > 2 {
            return false
        }

        let content = self.currencyNumberFormatter.string(from: number)
        self.currencyAmountLabel.text = content

        return true
    }
}

extension PaymentController: UIToolbarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
