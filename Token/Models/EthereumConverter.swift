import UIKit
import SweetSwift

struct EthereumConverter {

    public static var latestExchangeRate = Decimal(10.0)

    public static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    public static var weisToEtherPowerOf10Constant: Int16 {
        get {
            return Int16(self.weisToEtherConstant.stringValue.length - 1)
        }
    }

    public static func ethereumValueString(forEther balance: NSDecimalNumber) -> String {
        return "\(balance.toDecimalString) ETH"
    }

    public static func dollarValueString(forWei balance: NSDecimalNumber) -> String {
        let ether = balance.dividing(by: self.weisToEtherConstant)
        // Conversion from https://www.coinbase.com/charts
        let currentUSDConversion = NSDecimalNumber(decimal: self.latestExchangeRate)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currencyAccounting
        numberFormatter.locale = Locale(identifier: "en_US")

        let usd: NSDecimalNumber = currentUSDConversion.multiplying(by: ether)

        return numberFormatter.string(from: usd)!
    }
}
