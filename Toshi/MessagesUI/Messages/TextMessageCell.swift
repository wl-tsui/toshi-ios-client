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

final class TextMessageCell: UITableViewCell {

    private(set) lazy var textView: UITextView = {
        let view = UITextView()

        view.font = Theme.regular(size: 17)
        view.dataDetectorTypes = [.link]
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.contentMode = .topLeft
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0
        view.textContainerInset = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 10.0)

        self.prepareForSuperview(view)

        return view
    }()

    fileprivate lazy var container: UIView = {
        return UIView(withAutoLayout: true)
    }()

    private(set) lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 17.0
        imageView.layer.masksToBounds = true

        return imageView
    }()

    fileprivate lazy var containerLeftEqualConstraint: NSLayoutConstraint = {
        return self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 57.0)
    }()

    fileprivate lazy var containerRightEqualConstraint: NSLayoutConstraint = {
        return self.container.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16.0)
    }()

    fileprivate lazy var containerLeftSpace: NSLayoutConstraint = {
        return self.container.leftAnchor.constraint(greaterThanOrEqualTo: self.contentView.leftAnchor, constant: 56.0)
    }()

    fileprivate lazy var containerRightSpace: NSLayoutConstraint = {
        return self.container.rightAnchor.constraint(lessThanOrEqualTo: self.contentView.rightAnchor, constant: -16)
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.addSubviewsAndConstrains()
    }

    fileprivate var linkTintColor: UIColor {
        return self.isOutgoing == true ? Theme.outgoingMessageTextColor : Theme.tintColor
    }

    fileprivate let usernameDetector = try! NSRegularExpression(pattern: " ?(@[a-zA-Z][a-zA-Z0-9_]{2,59}) ?", options: [.caseInsensitive, .useUnicodeWordBoundaries])

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        if let text = self.textView.attributedText?.mutableCopy() as? NSMutableAttributedString {
            let range = NSRange(location: 0, length: text.string.length)

            text.removeAttribute(NSLinkAttributeName, range: range)
            text.removeAttribute(NSForegroundColorAttributeName, range: range)
            text.removeAttribute(NSUnderlineStyleAttributeName, range: range)

            self.textView.attributedText = text
        }

        self.containerLeftEqualConstraint.isActive = false
        self.containerRightEqualConstraint.isActive = false
    }

    var isOutgoing = false {
        didSet {
            self.avatarImageView.isHidden = isOutgoing
            self.textView.textColor = self.isOutgoing ? Theme.lightTextColor : Theme.darkTextColor
            let screenMargin: CGFloat = UIScreen.main.bounds.width * 0.3

            if isOutgoing {
                self.textView.textAlignment = .right

                self.containerLeftSpace.constant = screenMargin
                self.containerRightEqualConstraint.isActive = true
                self.containerLeftEqualConstraint.isActive = false
                self.containerRightSpace.isActive = false
            } else {
                self.textView.textAlignment = .left
                self.containerRightSpace.isActive = true
                self.containerRightSpace.constant = -screenMargin

                self.containerLeftEqualConstraint.isActive = true
                self.containerRightEqualConstraint.isActive = false
            }

            self.container.backgroundColor = self.isOutgoing ? Theme.outgoingMessageBackgroundColor : Theme.incomingMessageBackgroundColor

            self.textView.linkTextAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSForegroundColorAttributeName: self.linkTintColor]
            self.detectUsernameLinksIfNeeded()
        }
    }


    fileprivate func prepareForSuperview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
    }

    fileprivate func addSubviewsAndConstrains() {
        self.contentView.backgroundColor = Theme.messageViewBackgroundColor

        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16.0).isActive = true
        self.avatarImageView.set(height: 34.0)
        self.avatarImageView.set(width: 34.0)
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5.0).isActive = true

        self.contentView.addSubview(self.container)

        self.containerLeftSpace.isActive = true
        self.containerRightSpace.isActive = true

        self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5.0).isActive = true
        self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5.0).isActive = true

        self.container.addSubview(self.textView)
        self.textView.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -10.0).isActive = true
        self.textView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 10.0).isActive = true
        self.textView.topAnchor.constraint(equalTo: self.container.topAnchor).isActive = true
        self.textView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor).isActive = true
        
        self.container.layer.cornerRadius = 14.0
        self.container.layer.masksToBounds = true
    }

    fileprivate func detectUsernameLinksIfNeeded() {
        guard self.frame.isEmpty == false else { return }

        if let text = self.textView.attributedText?.mutableCopy() as? NSMutableAttributedString {
            let range = NSRange(location: 0, length: text.string.length)

            self.usernameDetector.enumerateMatches(in: text.string, options: [], range: range) { result, _, _ in

                if let result = result {
                    let attributes: [String: Any] = [
                        NSLinkAttributeName: "toshi://username:\((text.string as NSString).substring(with: result.rangeAt(1)))",
                        NSForegroundColorAttributeName: self.linkTintColor,
                        NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                        ]

                    text.addAttributes(attributes, range: result.rangeAt(1))
                }
            }

            self.textView.attributedText = text
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
