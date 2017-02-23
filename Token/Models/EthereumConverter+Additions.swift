import Foundation
import UIKit

extension EthereumConverter {
    public static func balanceAttributedString(for balance: NSDecimalNumber) -> NSAttributedString {
        let usdText = self.dollarValueString(forWei: balance)
        let etherText = self.ethereumValueString(forEther: balance.dividing(by: self.weisToEtherConstant).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior))

        let text = usdText + " · " + etherText
        let coloredPart = etherText
        let range = (text as NSString).range(of: coloredPart)

        let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: Theme.regular(size: 15)])
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.greyTextColor, range: range)
        
        return attributedString
    }
}
