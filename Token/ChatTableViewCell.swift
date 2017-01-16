import UIKit
import SweetUIKit

class ChatCell: UITableViewCell {
    var thread: TSThread? {
        didSet {
            self.usernameLabel.text = self.thread?.name()
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

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.accessoryType = .disclosureIndicator

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)

        self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 12).isActive = true

        self.usernameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: 12).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -12).isActive = true
        self.usernameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -12).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
