import UIKit
import SweetSwift

struct EthereumConverter {

    static let forcedLocale = "en_US"

    public static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    public static var weisToEtherPowerOf10Constant: Int16 {
        get {
            return Int16(self.weisToEtherConstant.stringValue.length - 1)
        }
    }

    public static func localFiatToEther(forFiat balance: NSNumber) -> NSDecimalNumber {
        let etherValue = balance.decimalValue / EthereumAPIClient.shared.exchangeRate

        return NSDecimalNumber(decimal: etherValue).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)
    }

    public static func ethereumValueString(forEther balance: NSDecimalNumber) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 4
        numberFormatter.maximumFractionDigits = 4

        return "\(numberFormatter.string(from: balance)!) ETH"
    }

    public static func ethereumValueString(forWei balance: NSDecimalNumber) -> String {
        return self.ethereumValueString(forEther: balance.dividing(by: self.weisToEtherConstant).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior))
    }

    public static func fiatValueString(forWei balance: NSDecimalNumber) -> String {
        let ether = balance.dividing(by: self.weisToEtherConstant)
        let currentFiatConversion = NSDecimalNumber(decimal: EthereumAPIClient.shared.exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: self.forcedLocale)

        return numberFormatter.string(from: fiat)!
    }

    public static func balanceAttributedString(forWei balance: NSDecimalNumber) -> NSAttributedString {
        let fiatText = "\(self.fiatValueString(forWei: balance)) \(Locale(identifier: self.forcedLocale).currencyCode!)"
        let etherText = self.ethereumValueString(forWei: balance)

        let fiatTextFull = fiatText + " · "
        let text = fiatTextFull + etherText
        let etherRange = (text as NSString).range(of: etherText)
        let fiatRange = (text as NSString).range(of: fiatTextFull)

        let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: Theme.regular(size: 15)])
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.greyTextColor, range: etherRange)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.darkTextColor, range: fiatRange)

        return attributedString
    }
}
