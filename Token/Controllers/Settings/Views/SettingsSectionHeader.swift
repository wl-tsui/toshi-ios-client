import UIKit
import SweetUIKit

class SettingsSectionHeader: UIView {

    lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.greyTextColor
        view.font = Theme.regular(size: 14)

        return view
    }()

    lazy var errorLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.errorColor
        view.font = Theme.regular(size: 14)
        view.textAlignment = .right

        return view
    }()

    lazy var errorImage: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "error")

        return view
    }()

    convenience init(title: String, error: String? = nil) {
        self.init()

        let margin: CGFloat = 16

        self.titleLabel.text = title
        self.addSubview(self.titleLabel)

        if let error = error {

            self.errorLabel.text = error
            self.addSubview(self.errorLabel)
            self.addSubview(self.errorImage)

            NSLayoutConstraint.activate([
                self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
                self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin),

                self.errorImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 3),
                self.errorImage.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -margin),
                self.errorImage.widthAnchor.constraint(equalToConstant: 12),
                self.errorImage.heightAnchor.constraint(equalToConstant: 12),

                self.errorLabel.topAnchor.constraint(equalTo: self.topAnchor),
                self.errorLabel.leftAnchor.constraint(equalTo: self.titleLabel.rightAnchor),
                self.errorLabel.rightAnchor.constraint(equalTo: self.errorImage.leftAnchor, constant: -5),
            ])
        } else {
            NSLayoutConstraint.activate([
                self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
                self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin),
                self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -margin),
            ])
        }
    }
}
