import Foundation
import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {

        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)

        return ceil(boundingBox.height)
    }
}

extension NSAttributedString {

    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {

    var hasEmojiOnly: Bool {
        var emojiOnly = false

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600 ... 0x1F64F, // Emoticons
                 0x1F300 ... 0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680 ... 0x1F6FF, // Transport and Map
                 0x2600 ... 0x26FF, // Misc symbols
                 0x2700 ... 0x27BF, // Dingbats
                 0xFE00 ... 0xFE0F: // Variation Selectors
                emojiOnly = true
            default:
                emojiOnly = false
                break
            }
        }

        return emojiOnly
    }
}

extension UIView {

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath

        if let mask = self.layer.mask as? CAShapeLayer {
            mask.path = path
        } else {
            let mask = CAShapeLayer()
            mask.path = path
            self.layer.mask = mask
        }

        self.setNeedsDisplay()
    }
}

extension UIViewAnimationOptions {

    static var easeIn: UIViewAnimationOptions {
        return [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction]
    }

    static var easeOut: UIViewAnimationOptions {
        return [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    }
}
