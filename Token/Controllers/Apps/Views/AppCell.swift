import UIKit
import SweetUIKit

class AppCell: UICollectionViewCell {
    static let avatarSize = CGFloat(89)

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)

        return view
    }()

    lazy var displayNameLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 15)
        label.textColor = Theme.darkTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    lazy var categoryLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 14)
        label.textColor = Theme.lightGreyTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    lazy var rankingImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "two-star")

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.displayNameLabel)
        self.contentView.addSubview(self.categoryLabel)
        self.contentView.addSubview(self.rankingImageView)

        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.avatarImageView.heightAnchor.constraint(equalToConstant: AppCell.avatarSize).isActive = true
        self.avatarImageView.widthAnchor.constraint(equalToConstant: AppCell.avatarSize).isActive = true

        self.displayNameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 5).isActive = true
        self.displayNameLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.displayNameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.categoryLabel.topAnchor.constraint(equalTo: self.displayNameLabel.bottomAnchor, constant: 5).isActive = true
        self.categoryLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.categoryLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.rankingImageView.topAnchor.constraint(equalTo: self.categoryLabel.bottomAnchor, constant: 5).isActive = true
        self.rankingImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
    }

    var app: App? {
        didSet {
            guard let app = self.app else {
                self.displayNameLabel.text = nil
                self.avatarImageView.image = nil
                return
            }

            self.displayNameLabel.text = app.displayName
            self.categoryLabel.text = app.category

            if let image = app.image {
                self.avatarImageView.image = image
            } else {
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
