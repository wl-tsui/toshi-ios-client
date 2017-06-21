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
import SweetUIKit
import SweetSwift
import SweetFoundation

/// ChatsTableController cells.
class ChatCell: UITableViewCell {
    var thread: TSThread? {
        didSet {
            // last visible message
            if let message = self.thread?.messages.last, let messageBody = message.body {

                switch SofaType(sofa: messageBody) {
                case .message:
                    self.lastMessageLabel.attributedText = NSMutableAttributedString(string: SofaMessage(content: messageBody).body, attributes: self.messageAttributes)
                case .paymentRequest:
                    self.lastMessageLabel.attributedText = NSMutableAttributedString(string: SofaPaymentRequest(content: messageBody).body, attributes: self.messageAttributes)
                default:
                    self.lastMessageLabel.attributedText = nil
                }
            } else {
                self.lastMessageLabel.attributedText = nil
            }

            // date
            if let date = self.thread?.lastMessageDate() {
                if DateTimeFormatter.isDate(date, sameDayAs: Date()) {
                    self.lastMessageDateLabel.text = DateTimeFormatter.timeFormatter.string(from: date)
                } else {
                    self.lastMessageDateLabel.text = DateTimeFormatter.dateFormatter.string(from: date)
                }
            }

            // unread badge
            if let thread = self.thread {
                let count = TSMessagesManager.shared().unreadMessages(in: thread)
                if count > 0 {
                    self.unreadLabel.text = "\(count)"
                    self.unreadView.isHidden = false
                    self.lastMessageDateLabel.textColor = Theme.tintColor
                } else {
                    self.unreadLabel.text = nil
                    self.unreadView.isHidden = true
                    self.lastMessageDateLabel.textColor = Theme.greyTextColor
                }
            }

            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            if let contact = delegate.contactsManager.tokenContact(forAddress: self.thread?.contactIdentifier() ?? "") {
                self.updateContact(contact)
            } else {
                IDAPIClient.shared.retrieveContact(username: self.thread?.contactIdentifier() ?? "") { contact in
                    guard let contact = contact else { return }
                    self.updateContact(contact)
                }
            }

            if let lastMessage = self.lastMessageLabel.text, !lastMessage.isEmpty {
                self.textGuideHeight.constant = 5
            } else {
                self.textGuideHeight.constant = 0
            }
        }
    }

    lazy var messageAttributes: [String: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.5
        paragraphStyle.paragraphSpacing = -4
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            NSFontAttributeName: Theme.regular(size: 15),
            NSForegroundColorAttributeName: Theme.greyTextColor,
            NSParagraphStyleAttributeName: paragraphStyle,
        ]
    }()

    // Container that contains the unread label and
    // provides a colored background with content insets.
    lazy var unreadView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor
        view.layer.cornerRadius = 12
        view.clipsToBounds = true

        self.unreadLabel.font = Theme.regular(size: 15)
        self.unreadLabel.textColor = Theme.lightTextColor
        self.unreadLabel.textAlignment = .center
        view.addSubview(self.unreadLabel)

        self.unreadLabel.edges(to: view, insets: UIEdgeInsetsMake(0, 5, 0, -5))

        return view
    }()

    lazy var unreadLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.semibold(size: 15)
        view.textColor = Theme.lightTextColor
        view.textAlignment = .center

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView()

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.semibold(size: 16)
        view.textColor = Theme.darkTextColor

        return view
    }()

    lazy var lastMessageLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 2

        return view
    }()

    lazy var lastMessageDateLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.regular(size: 15)
        view.textAlignment = .right
        view.textColor = Theme.tintColor

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var guides: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide(), UILayoutGuide()]
    }()

    lazy var textGuide: UILayoutGuide = {
        UILayoutGuide()
    }()

    lazy var textGuideHeight: NSLayoutConstraint = {
        self.textGuide.height(0)
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.accessoryType = .disclosureIndicator

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Theme.cellSelectionColor
        self.selectedBackgroundView = selectedBackgroundView

        self.contentView.addSubview(self.unreadView)
        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.lastMessageLabel)
        self.contentView.addSubview(self.lastMessageDateLabel)
        self.contentView.addSubview(self.separatorView)

        for guide in guides {
            self.contentView.addLayoutGuide(guide)
        }

        self.contentView.addLayoutGuide(self.textGuide)

        let margin: CGFloat = 15.0

        self.guides[0].left(to: contentView, offset: margin)
        self.guides[0].centerY(to: contentView)

        self.guides[1].leftToRight(of: self.guides[0], offset: margin)
        self.guides[1].centerY(to: contentView)

        self.guides[2].top(to: self.guides[1])
        self.guides[2].leftToRight(of: self.guides[1], offset: margin)
        self.guides[2].right(to: contentView, offset: 0)

        self.avatarImageView.size(CGSize(width: 44, height: 44))
        self.avatarImageView.centerY(to: self.guides[0])
        self.avatarImageView.left(to: self.guides[0])
        self.avatarImageView.right(to: self.guides[0])

        self.usernameLabel.top(to: self.guides[1])
        self.usernameLabel.left(to: self.guides[1])
        self.usernameLabel.right(to: self.guides[1])

        self.textGuide.topToBottom(of: self.usernameLabel)
        self.textGuide.left(to: self.guides[1])
        self.textGuide.right(to: self.guides[1])

        self.lastMessageLabel.topToBottom(of: self.textGuide)
        self.lastMessageLabel.left(to: self.guides[1])
        self.lastMessageLabel.right(to: self.guides[1])
        self.lastMessageLabel.bottom(to: self.guides[1])

        self.lastMessageDateLabel.top(to: self.contentView, offset: 10)
        self.lastMessageDateLabel.left(to: self.guides[2])
        self.lastMessageDateLabel.right(to: self.guides[2])

        self.unreadView.topToBottom(of: self.lastMessageDateLabel, offset: 12)
        self.unreadView.right(to: self.guides[2])
        self.unreadView.height(24)
        self.unreadView.width(24, relation: .equalOrGreater)

        self.separatorView.left(to: self.guides[1])
        self.separatorView.right(to: self)
        self.separatorView.height(Theme.borderHeight)
        self.separatorView.bottom(to: self.contentView)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func updateContact(_ contact: TokenUser) {
        self.usernameLabel.text = !contact.name.isEmpty ? contact.name : contact.displayUsername
        self.thread?.cachedContactIdentifier = self.usernameLabel.text
        self.avatarImageView.image = contact.avatar

        if contact.avatarPath.length > 0 {
            IDAPIClient.shared.downloadAvatar(path: contact.avatarPath) { image in
                self.avatarImageView.image = image
            }
        }
    }
}
