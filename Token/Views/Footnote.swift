import UIKit
import SweetUIKit

class Footnote: UIView {

    private lazy var icon: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "info")

        return view
    }()

    private lazy var textLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0

        return view
    }()

    convenience init(text: String) {
        self.init(withAutoLayout: true)

        self.addSubview(self.icon)
        self.addSubview(self.textLabel)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 5

        let attributes: [String: Any] = [
            NSFontAttributeName: Theme.regular(size: 13),
            NSForegroundColorAttributeName: Theme.greyTextColor,
            NSParagraphStyleAttributeName: paragraphStyle,
        ]

        self.textLabel.attributedText = NSMutableAttributedString(string: text, attributes: attributes)

        let imageSize = self.icon.image?.size ?? .zero

        NSLayoutConstraint.activate([
            self.icon.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            self.icon.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.icon.widthAnchor.constraint(equalToConstant: imageSize.width),
            self.icon.heightAnchor.constraint(equalToConstant: imageSize.height),

            self.textLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.textLabel.leftAnchor.constraint(equalTo: self.icon.rightAnchor, constant: 6),
            self.textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.textLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
        ])
    }
}
