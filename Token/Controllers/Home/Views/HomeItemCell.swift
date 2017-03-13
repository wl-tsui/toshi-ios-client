import UIKit
import SweetUIKit

class HomeItemCell: UICollectionViewCell {
    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)

        return view
    }()

    lazy var displayNameLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 14)
        label.textColor = Theme.darkTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.displayNameLabel)

        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.avatarImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true
        self.avatarImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true

        self.displayNameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor).isActive = true
        self.displayNameLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.displayNameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.displayNameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }

    var app: TokenContact? {
        didSet {
            guard let app = self.app else {
                self.displayNameLabel.text = nil
                self.avatarImageView.image = nil

                return
            }

            self.displayNameLabel.text = app.displayName

            if let image = self.app?.avatar {
                self.avatarImageView.image = image
            } else if let app = self.app {
                AppsAPIClient.shared.downloadImage(for: app) { image in
                    self.avatarImageView.image = image
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
