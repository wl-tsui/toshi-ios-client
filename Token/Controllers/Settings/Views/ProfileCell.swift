import UIKit
import SweetUIKit

class ProfileCell: BaseCell {

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)
        view.numberOfLines = 0

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.greyTextColor
        view.font = Theme.regular(size: 14)
        view.numberOfLines = 0

        return view
    }()

    lazy var ratingView: RatingView = {
        let view = RatingView(numberOfStars: 5)
        view.set(rating: 3.5)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var ratingLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        view.textColor = Theme.greyTextColor
        view.font = Theme.regular(size: 14)
        view.textAlignment = .right
        view.numberOfLines = 0

        return view
    }()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.backgroundColor = .lightGray

        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let margin: CGFloat = 16
        let interLabelMargin: CGFloat = 6
        let imageSize: CGFloat = 44

        self.contentView.addSubview(self.avatarImageView)

        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.layer.cornerRadius = imageSize / 2

        self.avatarImageView.set(height: imageSize)
        self.avatarImageView.set(width: imageSize)
        NSLayoutConstraint.activate([
            self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
        ])

        let namesContainer = UIView(withAutoLayout: true)
        self.contentView.addSubview(namesContainer)

        NSLayoutConstraint.activate([
            namesContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin),
            namesContainer.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin),
            namesContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin)
        ])

        namesContainer.addSubview(self.usernameLabel)
        namesContainer.addSubview(self.nameLabel)

        NSLayoutConstraint.activate([
            self.nameLabel.topAnchor.constraint(equalTo: namesContainer.topAnchor),
            self.nameLabel.leftAnchor.constraint(equalTo: namesContainer.leftAnchor),
            self.nameLabel.rightAnchor.constraint(equalTo: namesContainer.rightAnchor),
        ])

        NSLayoutConstraint.activate([
            self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: interLabelMargin),
            self.usernameLabel.leftAnchor.constraint(equalTo: namesContainer.leftAnchor),
            self.usernameLabel.rightAnchor.constraint(equalTo: namesContainer.rightAnchor),
            self.usernameLabel.bottomAnchor.constraint(lessThanOrEqualTo: namesContainer.bottomAnchor),
        ])

        let ratingContainer = UIView(withAutoLayout: true)
        self.contentView.addSubview(ratingContainer)

        NSLayoutConstraint.activate([
            ratingContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin),
            ratingContainer.leftAnchor.constraint(equalTo: namesContainer.rightAnchor, constant: margin),
            ratingContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin),
            ratingContainer.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -40),
        ])

        ratingContainer.addSubview(self.ratingView)

        NSLayoutConstraint.activate([
            self.ratingView.topAnchor.constraint(equalTo: ratingContainer.topAnchor, constant: 5),
            self.ratingView.leftAnchor.constraint(greaterThanOrEqualTo: ratingContainer.leftAnchor),
            self.ratingView.rightAnchor.constraint(equalTo: ratingContainer.rightAnchor),
        ])

        namesContainer.addSubview(self.ratingLabel)

        self.ratingLabel.text = "(99999999)"
        NSLayoutConstraint.activate([
            self.ratingLabel.topAnchor.constraint(equalTo: self.ratingView.bottomAnchor, constant: interLabelMargin),
            self.ratingLabel.leftAnchor.constraint(equalTo: ratingContainer.leftAnchor),
            self.ratingLabel.rightAnchor.constraint(equalTo: ratingContainer.rightAnchor),
            self.ratingLabel.bottomAnchor.constraint(lessThanOrEqualTo: ratingContainer.bottomAnchor),
        ])

        if let displayName = User.current?.name, displayName.length > 0, let username = User.current?.username {
            self.nameLabel.text = displayName
            self.usernameLabel.text = "@\(username)"
        } else if let username = User.current?.username {
            self.usernameLabel.text = nil
            self.nameLabel.text = "@\(username)"
        }

        if let image = User.current?.avatar {
            self.avatarImageView.image = image
        } else if let avatarPath = User.current?.avatarPath {
            IDAPIClient.shared.downloadAvatar(path: avatarPath) { image in
                User.current?.avatar = image
                self.avatarImageView.image = image
            }
        }
    }
}
