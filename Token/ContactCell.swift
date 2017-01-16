import UIKit

class ContactCell: UITableViewCell {
    var contact: TokenContact? {
        didSet {
            // self.avatarImageView.image = self.contact?.avatar
            self.usernameLabel.text = self.contact?.username
            self.nameLabel.text = self.contact?.name
        }
    }

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = [#imageLiteral(resourceName: "daniel"), #imageLiteral(resourceName: "igor"), #imageLiteral(resourceName: "colin")].any

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.nameLabel)

        let margin: CGFloat = 12.0
        let size: CGFloat = 44.0

        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.layer.cornerRadius = size/2

        self.avatarImageView.set(height: size)
        self.avatarImageView.set(width: size)
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true
        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true

        self.nameLabel.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true

        self.usernameLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: size).isActive = true
        self.usernameLabel.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.nameLabel.rightAnchor, constant: margin).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
