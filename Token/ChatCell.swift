import UIKit
import SweetUIKit
import SweetFoundation

/// ChatsTableController cells.
class ChatCell: UITableViewCell {
    var thread: TSThread? {
        didSet {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }

            let tokenContact = delegate.contactsManager.tokenContact(forAddress: self.thread?.contactIdentifier() ?? "")
            self.usernameLabel.text = tokenContact?.username == nil ? "" : "@\(tokenContact!.username)"

            if let sofaMessage = self.thread?.lastMessageLabel(), sofaMessage.length > 0 && SofaType(sofa: sofaMessage) == .message {
                self.lastMessageLabel.text = SofaMessage(content: sofaMessage).body
            } else {
                self.lastMessageLabel.text = nil
            }

            // TODO: placeholder for now, remove it once we have avatar support on the API level
            if self.avatarImageView.image == nil {
                self.avatarImageView.image = self.thread?.image() ?? [#imageLiteral(resourceName: "daniel")].any
            }

            if let date = self.thread?.lastMessageDate() {
                if DateTimeFormatter.isDate(date, sameDayAs: Date()) {
                    self.lastMessageDateLabel.text = DateTimeFormatter.timeFormatter.string(from: date)
                } else {
                    self.lastMessageDateLabel.text = DateTimeFormatter.dateFormatter.string(from: date)
                }
            }
        }
    }

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.clipsToBounds = true
        view.layer.cornerRadius = 22

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.semibold(size: 15)

        return view
    }()

    lazy var lastMessageLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 14)
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var lastMessageDateLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 14)
        view.textAlignment = .right
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.lastMessageLabel)
        self.contentView.addSubview(self.lastMessageDateLabel)
        self.contentView.addSubview(self.separatorView)

        let height: CGFloat = 24.0
        let margin: CGFloat = 16.0

        self.avatarImageView.set(height: 44)
        self.avatarImageView.set(width: 44)
        self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.self.lastMessageDateLabel.leftAnchor, constant: -margin).isActive = true

        self.lastMessageDateLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.lastMessageDateLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.lastMessageDateLabel.rightAnchor.constraint(equalTo: self.self.contentView.rightAnchor, constant: -margin).isActive = true

        self.lastMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.lastMessageLabel.topAnchor.constraint(equalTo: self.lastMessageDateLabel.bottomAnchor).isActive = true
        self.lastMessageLabel.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor).isActive = true
        self.lastMessageLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.lastMessageLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin).isActive = true
        self.lastMessageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true

        self.separatorView.set(height: 1.0)
        self.separatorView.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
