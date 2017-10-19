// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

/// Displays user's contacts.
class ContactCell: UITableViewCell {
    var contact: TokenUser? {
        didSet {
            if let contact = self.contact {
                if contact.name.isEmpty {
                    nameLabel.text = contact.displayUsername
                    usernameLabel.text = nil
                } else {
                    usernameLabel.text = contact.displayUsername
                    nameLabel.text = contact.name
                }

                AvatarManager.shared.avatar(for: contact.avatarPath) { [weak self] image, path in
                    if image != nil && contact.avatarPath == path {
                        self?.avatarImageView.image = image
                    }
                }

                return
            }

            usernameLabel.text = nil
            nameLabel.text = nil
            avatarImageView.image = nil
        }
    }

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredSemibold()

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.greyTextColor
        view.font = Theme.preferredRegularSmall()

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        nameLabel.text = nil
        usernameLabel.text = nil
        contact = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorView)

        let margin: CGFloat = 16.0
        let interLabelMargin: CGFloat = 6.0
        let imageSize: CGFloat = 48.0
        let height: CGFloat = 24.0

        avatarImageView.size(CGSize(width: imageSize, height: imageSize))
        avatarImageView.centerY(to: contentView)
        avatarImageView.left(to: contentView, offset: margin)

        nameLabel.height(height, relation: .equalOrGreater)
        nameLabel.top(to: contentView, offset: margin)
        nameLabel.leftToRight(of: avatarImageView, offset: 10)
        nameLabel.right(to: contentView, offset: -margin)

        usernameLabel.height(height, relation: .equalOrGreater)
        usernameLabel.topToBottom(of: nameLabel)
        usernameLabel.leftToRight(of: avatarImageView, offset: 10)
        usernameLabel.right(to: contentView, offset: -margin)

        separatorView.height( Theme.borderHeight)
        separatorView.topToBottom(of: usernameLabel, offset: interLabelMargin)
        separatorView.left(to: contentView, offset: margin)
        separatorView.bottom(to: contentView)
        separatorView.right(to: contentView, offset: -margin)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }
}
