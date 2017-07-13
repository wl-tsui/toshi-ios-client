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

import Foundation

protocol ImageMessageCellDelegate: class {
    func didTapImage(in cell: ImageMessageCell)
}

final class ImageMessageCell: UITableViewCell {

    var tapDelegate: ImageMessageCellDelegate?

    var isOutgoing = false {
        didSet {
            self.avatarImageView.isHidden = isOutgoing

            self.imageRightSpaceConstraint.isActive = isOutgoing
            self.imageLeftSpaceConstraint.isActive = !isOutgoing
        }
    }

    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
    }()

    fileprivate lazy var imageLeftSpaceConstraint: NSLayoutConstraint = {
        return self.messageImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 57.0)
    }()

    fileprivate lazy var imageRightSpaceConstraint: NSLayoutConstraint = {
        return self.messageImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16.0)
    }()

    private(set) lazy var messageImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(self.tapGesture)

        return view
    }()

    private(set) lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 17.0
        imageView.layer.masksToBounds = true

        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.addSubviewsAndConstrains()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.messageImageView.image = nil
        self.imageLeftSpaceConstraint.isActive = false
        self.imageRightSpaceConstraint.isActive = true
    }

    fileprivate func addSubviewsAndConstrains() {
        self.contentView.backgroundColor = Theme.messageViewBackgroundColor

        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16.0).isActive = true
        self.avatarImageView.set(height: 34.0)
        self.avatarImageView.set(width: 34.0)
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10.0).isActive = true

        self.contentView.addSubview(self.messageImageView)

        self.imageRightSpaceConstraint.isActive = true
        self.imageLeftSpaceConstraint.isActive = false

        self.messageImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10.0).isActive = true
        self.messageImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10.0).isActive = true

        self.messageImageView.layer.cornerRadius = 16.0
        self.messageImageView.layer.masksToBounds = true
    }

    @objc fileprivate func didTapImageView(_ gesture: UITapGestureRecognizer) {
        self.tapDelegate?.didTapImage(in: self)
    }

    func setup(with image: UIImage?) {
        guard let image = image as UIImage? else { return }

        self.messageImageView.widthAnchor.constraint(equalToConstant: image.size.width)
        self.messageImageView.heightAnchor.constraint(equalToConstant: image.size.height)
        self.messageImageView.image = image
        
        self.contentView.layoutIfNeeded()
    }
}
