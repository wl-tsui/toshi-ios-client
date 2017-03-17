import UIKit
import SweetUIKit

class TextLabel: UILabel {
    
    convenience init(_ text: String) {
        self.init(withAutoLayout: true)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.5
        paragraphStyle.paragraphSpacing = -4
        
        let attributes: [String : Any] = [
            NSFontAttributeName: Theme.regular(size: 16),
            NSForegroundColorAttributeName: Theme.greyTextColor,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        self.attributedText = NSMutableAttributedString(string: text, attributes: attributes)
        self.numberOfLines = 0
    }
}
