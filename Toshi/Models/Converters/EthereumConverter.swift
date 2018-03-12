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
import SweetSwift

struct EthereumConverter {

    /// The conversion rate between wei and eth. Each eth is made up of 1 x 10^18 wei.
    static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    /// Each eth is made up of 1 x 10^18 wei.
    static var weisToEtherPowerOf10Constant: Int16 {
        return Int16(18)
    }

    /// Converts local currency to ethereum. Currently only supports USD.
    ///
    /// - Parameter balance: the value in USD to be converted to eth.
    /// - Returns: the eth value.
    static func localFiatToEther(forFiat balance: NSNumber, exchangeRate: Decimal) -> NSDecimalNumber {
        let etherValue = balance.decimalValue / exchangeRate

        return NSDecimalNumber(decimal: etherValue).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)
    }

    /// Converts wei to ethereum. Allows specification of whether you
    ///
    /// - Parameters:
    ///   - wei: The Wei to convert
    ///   - rounded: True to round according to wei rounding behavior, false not to. Defaults to false
    /// - Returns: The ether value of the passed in wei
    static func weiToEther(_ wei: NSDecimalNumber, rounded: Bool = false) -> NSDecimalNumber {
        let converted = wei.dividing(by: weisToEtherConstant)

        guard rounded else {
            return converted
        }

        return converted.rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)
    }

    /// Converts ethereum to wei
    ///
    /// - Parameter ether: The ether value to convert
    /// - Returns: The value in Wei
    static func etherToWei(_ ether: NSDecimalNumber) -> NSDecimalNumber {
        return ether.multiplying(by: weisToEtherConstant)
    }

    /// Returns the string representation of an eth value.
    /// Example: "9.2 ETH"
    ///
    /// - Parameters:
    ///    - balance: the value in eth
    ///    - withSymbol: True to add the ETH symbol to the end of the string, false not to. Defaults to true.
    ///    - fractionDigits: The number of digits after the decimal separator allowed as input and output.
    /// - Returns: the string representation
    static func ethereumValueString(forEther balance: NSDecimalNumber, withSymbol: Bool = true, fractionDigits: Int = 4) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = fractionDigits
        numberFormatter.maximumFractionDigits = fractionDigits

        let balanceString = numberFormatter.string(from: balance)!

        guard withSymbol else {
            return balanceString
        }

        return "\(balanceString) ETH"
    }

    /// String representation in ETH for a given wei value.
    /// Example:
    ///     ethereumValueString(forWei: halfEthInWei) -> "0.5 ETH"
    ///     ethereumValueString(forWei: halfEthInWei, withSymbol: false) -> "0.5"
    ///
    /// - Parameters:
    ///    - balance: the wei value to be converted
    ///    - withSymbol: Whether to add the ETH symbol to the end of the string or not. Defaults to true
    ///    - fractionDigits: The number of digits after the decimal separator allowed as input and output.
    /// - Returns: the eth value in a string: "0.5 ETH" or "0.5"
    static func ethereumValueString(forWei balance: NSDecimalNumber, withSymbol: Bool = true, fractionDigits: Int = 4) -> String {
        return ethereumValueString(forEther: weiToEther(balance, rounded: true), withSymbol: withSymbol, fractionDigits: fractionDigits)
    }

    /// The fiat currency string representation for a given wei value
    ///
    /// - Parameter:
    ///    - balance: value in wei
    ///    - withCurrencyCode: Whether to add the currency code to the string or not. Defaults to true.
    /// - Returns: fiat string representation: "$10.50"
    static func fiatValueString(forWei balance: NSDecimalNumber, exchangeRate: Decimal, withCurrencyCode: Bool = true) -> String {
        let ether = weiToEther(balance)

        let currentFiatConversion = NSDecimalNumber(decimal: exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let locale = TokenUser.current?.cachedCurrencyLocale ?? Currency.forcedLocale
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = withCurrencyCode ? .currency : .decimal
        numberFormatter.locale = locale
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.currencyCode = TokenUser.current?.localCurrency

        return "\(numberFormatter.string(from: fiat)!)"
    }

    /// Fiat currency value string with redundant 3 letter code. "$4.99 USD"
    ///
    /// - Parameter balance: the value in wei
    /// - Returns: the fiat currency value with redundant 3 letter code for clarity.
    static func fiatValueStringWithCode(forWei balance: NSDecimalNumber, exchangeRate: Decimal) -> String {
        let locale = TokenUser.current?.cachedCurrencyLocale ?? Currency.forcedLocale
        let localCurrency = TokenUser.current?.localCurrency ?? Currency.forcedLocale.currencyCode

        let ether = weiToEther(balance)
        let currentFiatConversion = NSDecimalNumber(decimal: exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencyCode = localCurrency

        let fiatValueString = numberFormatter.string(from: fiat) ?? ""

        return numberFormatter.currencySymbol == numberFormatter.currencyCode ? fiatValueString : fiatValueString + " " + localCurrency!
    }

    /// Complete formatted string value for a given wei, with fiat aligned left and eth aligned right.
    ///    "$4.99 USD                        0.0050 ETH"
    ///    Fiat is black, and eth value is light grey.
    ///
    /// - Parameters:
    ///   - balance: the value in wei
    ///   - width: the width of the label, to adjust alignment.
    ///   - attributes: the attributes of the label, to copy them on the attributed string.
    /// - Returns: the attributed string to be displayed.
    static func balanceSparseAttributedString(forWei balance: NSDecimalNumber, exchangeRate: Decimal, width: CGFloat, attributes: [NSAttributedStringKey: Any]? = nil) -> NSAttributedString {
        let attributedString = balanceAttributedString(forWei: balance, exchangeRate: exchangeRate, attributes: attributes)
        guard let mutableAttributedString = attributedString.mutableCopy() as? NSMutableAttributedString else { return attributedString }

        let range = NSRange(location: 0, length: mutableAttributedString.length)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let nextTabStop = NSTextTab(textAlignment: .right, location: width, options: [:])
        paragraph.tabStops = [nextTabStop]
        mutableAttributedString.addAttribute(.paragraphStyle, value: paragraph, range: range)

        return mutableAttributedString
    }

    /// Complete formatted string value for a given wei, fully left aligned.
    ///    "$4.99 USD    0.0050 ETH"
    ///    Fiat is black, and eth value is light grey.
    ///
    /// - Parameters:
    ///   - balance: the value in wei
    ///   - attributes: the attributes of the label, to copy them on the attributed string.
    /// - Returns: the attributed string to be displayed.
    static func balanceAttributedString(forWei balance: NSDecimalNumber, exchangeRate: Decimal, attributes: [NSAttributedStringKey: Any]? = nil) -> NSAttributedString {

        let fiatText = fiatValueStringWithCode(forWei: balance, exchangeRate: exchangeRate)
        let etherText = ethereumValueString(forWei: balance)
        
        let fiatTextFull = fiatText + "\t"
        let text = fiatTextFull + etherText
        let etherRange = (text as NSString).range(of: etherText)
        let fiatRange = (text as NSString).range(of: fiatTextFull)

        let attributedString = NSMutableAttributedString(string: text, attributes: attributes ?? [.font: Theme.medium(size: 15)])
        attributedString.addAttribute(.foregroundColor, value: Theme.greyTextColor, range: etherRange)
        attributedString.addAttribute(.foregroundColor, value: Theme.darkTextColor, range: fiatRange)

        return attributedString
    }
}
