import UIKit
import SweetUIKit

class TitleLabel: UILabel {

    convenience init(_ title: String) {
        self.init(withAutoLayout: true)

        self.textColor = Theme.darkTextColor
        self.font = Theme.semibold(size: 18)
        self.numberOfLines = 0
        self.text = title
        self.textAlignment = .center
    }
}
