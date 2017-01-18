import UIKit
import SweetUIKit

/// ChatsTableController cells. Should merge with ContactCell.
class ChatCell: UITableViewCell {
    var thread: TSThread? {
        didSet {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }

            let tokenContact = delegate.contactsManager.tokenContact(forAddress: self.thread?.contactIdentifier() ?? "")
            self.nameLabel.text = tokenContact?.name
            self.usernameLabel.text = tokenContact?.username == nil ? "" : "@\(tokenContact!.username)"

            // TODO: placeholder for now, remove it once we have avatar support on the API level
            self.avatarImageView.image = self.thread?.image() ?? [#imageLiteral(resourceName: "daniel"), #imageLiteral(resourceName: "igor"), #imageLiteral(resourceName: "colin")].any
        }
    }

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.set(height: 44)
        view.set(width: 44)
        view.clipsToBounds = true
        view.layer.cornerRadius = 22

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = UIFont.systemFont(ofSize: 15)
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = UIFont.boldSystemFont(ofSize: 15)

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.accessoryType = .disclosureIndicator

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.separatorView)

        self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 12).isActive = true

        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: 12).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -12).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: 12).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -12).isActive = true
        self.usernameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -12).isActive = true

        self.separatorView.set(height: 1.0)
        self.separatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
