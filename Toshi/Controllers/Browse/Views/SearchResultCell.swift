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

class SearchResultCell: UITableViewCell {
    static let height: CGFloat = 50.0

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 17)

        return view
    }()

    lazy var subLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.textColor = Theme.greyTextColor
        view.font = Theme.regular(size: 13)

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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(subLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorView)

        let margin: CGFloat = 14.0
        let imageSize: CGFloat = 38.0

        avatarImageView.set(height: imageSize)
        avatarImageView.set(width: imageSize)
        avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        avatarImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin).isActive = true

        nameLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 10).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin).isActive = true

        subLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        subLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 10).isActive = true
        subLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin).isActive = true
        subLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true

        separatorView.set(height: Theme.borderHeight)
        separatorView.leftAnchor.constraint(equalTo: nameLabel.leftAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        subLabel.text = nil
        avatarImageView.image = nil
    }
}
