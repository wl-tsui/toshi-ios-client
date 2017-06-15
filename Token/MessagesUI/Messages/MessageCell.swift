import UIKit

protocol MessageCellDelegate {
    func didTapImage(in cell: MessageCell)
    func didTapRejectButton(_ cell: MessageCell)
    func didTapApproveButton(_ cell: MessageCell)
}

class MessageCell: UICollectionViewCell {

    var delegate: MessageCellDelegate?

    var indexPath: IndexPath?

    static var reuseIdentifier = "MessageCell"

    var titleFont: UIFont = Theme.regular(size: 18)

    var subtitleFont: UIFont = Theme.regular(size: 14)

    var statusFont: UIFont = Theme.regular(size: 13)

    var textFont: UIFont {
        guard let message = message, let text = message.text, text.hasEmojiOnly, text.characters.count < 4 else {
            if self.message?.type == .paymentRequest || self.message?.type == .payment {
                return Theme.regular(size: 14)
            }

            return Theme.regular(size: 17)
        }

        return Theme.regular(size: 50)
    }

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.titleFont

        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.textFont

        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)

        return view
    }()

    lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.subtitleFont
        view.textColor = Theme.tintColor

        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)

        return view
    }()

    lazy var imageView: MessageImageView = {
        let view = MessageImageView(frame: .zero)
        view.imageTap = {
            guard let indexPath = self.indexPath else { return }
            self.delegate?.didTapImage(in: self)
        }

        return view
    }()

    private lazy var container: UIView = {
        UIView()
    }()

    private lazy var avatar: UIImageView = {
        let view = UIImageView()

        return view
    }()

    lazy var statusLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.statusFont
        view.textColor = Theme.darkTextColor
        view.textAlignment = .center

        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)

        return view
    }()

    private lazy var avatarLeft: NSLayoutConstraint = {
        self.avatar.centerX(to: self.leftSpacing, isActive: false)
    }()

    private lazy var avatarRight: NSLayoutConstraint = {
        self.avatar.centerX(to: self.rightSpacing, isActive: false)
    }()

    private lazy var verticalGuides: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide(), UILayoutGuide(), UILayoutGuide()]
    }()

    private lazy var verticalGuidesConstraints: [NSLayoutConstraint] = {
        self.verticalGuides.map { guide in
            guide.height(0, priority: .high)
        }
    }()

    private lazy var bottomGuide: UILayoutGuide = {
        UILayoutGuide()
    }()

    private lazy var bottomConstraint: NSLayoutConstraint = {
        self.bottomGuide.height(0, priority: .high)
    }()

    private lazy var textLeftConstraints: NSLayoutConstraint = {
        self.textLabel.left(to: self.container, offset: self.horizontalMargin, isActive: false)
    }()

    private lazy var textRightConstraints: NSLayoutConstraint = {
        self.textLabel.right(to: self.container, offset: -self.horizontalMargin, isActive: false)
    }()

    private lazy var buttons: [MessageCellButton] = {
        [MessageCellButton(), MessageCellButton()]
    }()

    var isActionable: Bool? {
        didSet {
            // TODO: implement actionable state of the cell.
        }
    }

    private lazy var leftSpacing = UILayoutGuide()
    private lazy var rightSpacing = UILayoutGuide()

    private lazy var leftWidthSmall: NSLayoutConstraint = self.leftSpacing.width(10, relation: .equal, isActive: false)
    private lazy var rightWidthSmall: NSLayoutConstraint = self.rightSpacing.width(10, relation: .equal, isActive: false)
    private lazy var leftWidthBig: NSLayoutConstraint = self.leftSpacing.width(60, relation: .equalOrGreater, isActive: false)
    private lazy var rightWidthBig: NSLayoutConstraint = self.rightSpacing.width(60, relation: .equalOrGreater, isActive: false)

    private let horizontalMargin: CGFloat = 15

    var message: MessageModel? {
        didSet {
            guard let message = message else { return }

            self.isActionable = message.isActionable

            if let models = message.buttonModels {
                self.buttons[0].model = models[0]
                self.buttons[1].model = models[1]
            } else {
                self.buttons[0].model = nil
                self.buttons[1].model = nil
            }

            if let image = message.image {
                self.imageView.image = image
            } else {
                self.imageView.image = nil
            }

            self.titleLabel.text = message.title
            self.textLabel.text = message.text
            self.textLabel.font = textFont
            self.subtitleLabel.text = message.subtitle

            self.bottomConstraint.constant = 0

            self.container.backgroundColor = message.didSent ? Theme.outgoingMessageBackgroundColor : Theme.incomingMessageBackgroundColor
            self.titleLabel.textColor = message.didSent ? Theme.lightTextColor : Theme.darkTextColor
            self.textLabel.textColor = message.didSent ? Theme.lightTextColor : Theme.darkTextColor

            if message.didSent {
                self.avatarLeft.isActive = false
                self.avatarRight.isActive = true

                self.leftWidthSmall.isActive = false
                self.rightWidthBig.isActive = false
                self.leftWidthBig.isActive = true
                self.rightWidthSmall.isActive = true
            } else {
                self.avatarRight.isActive = false
                self.avatarLeft.isActive = true

                self.leftWidthBig.isActive = false
                self.rightWidthSmall.isActive = false
                self.leftWidthSmall.isActive = true
                self.rightWidthBig.isActive = true
            }

            if message.type == .paymentRequest || message.type == .payment {
                self.verticalGuidesConstraints[0].constant = 10
                self.verticalGuidesConstraints[1].constant = 5

                if let text = message.text {
                    self.verticalGuidesConstraints[2].constant = text.isEmpty ? 0 : 10
                } else {
                    self.verticalGuidesConstraints[2].constant = 0
                }

                self.verticalGuidesConstraints[3].constant = 10

                self.container.backgroundColor = .white

                self.titleLabel.textColor = Theme.tintColor
                self.subtitleLabel.textColor = Theme.mediumTextColor
                self.textLabel.textColor = Theme.darkTextColor
                self.statusLabel.textColor = Theme.mediumTextColor

                self.container.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
                self.container.layer.borderWidth = 1
                self.container.layer.cornerRadius = 16
            } else {
                self.verticalGuidesConstraints[0].constant = 0
                self.verticalGuidesConstraints[1].constant = 0
                self.verticalGuidesConstraints[2].constant = message.imageOnly ? 0 : 10
                self.verticalGuidesConstraints[3].constant = message.imageOnly ? 0 : 10

                self.container.layer.borderColor = nil
                self.container.layer.borderWidth = 0
                self.container.layer.cornerRadius = 6
            }

            if let text = message.text, text.hasEmojiOnly, text.characters.count < 4 {
                if message.image == nil {
                    self.container.backgroundColor = nil
                }
                self.textLeftConstraints.constant = 0
                self.textRightConstraints.constant = 0
                self.verticalGuidesConstraints[2].constant = 0
                self.verticalGuidesConstraints[3].constant = 0
            } else {
                self.textLeftConstraints.constant = horizontalMargin
                self.textRightConstraints.constant = -self.horizontalMargin
            }

            self.avatar.image = UIImage(named: "Avatar")
            self.statusLabel.text = nil

            if let title = titleLabel.text, !title.isEmpty {
                self.verticalGuidesConstraints[0].constant = 10
            }

            if let status = message.status, message.type == .status, case .neutral(let s) = status {
                self.statusLabel.text = s

                self.verticalGuidesConstraints[2].constant = 0
                self.verticalGuidesConstraints[3].constant = 0
                self.bottomConstraint.constant = 10
                self.avatar.image = nil
            }

            self.fixCorners()

            if !frame.isEmpty {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }

    required init?(coder _: NSCoder) { fatalError() }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.isOpaque = false

        contentView.addSubview(self.statusLabel)
        self.statusLabel.left(to: contentView)
        self.statusLabel.right(to: contentView)

        contentView.addLayoutGuide(self.leftSpacing)
        self.leftSpacing.top(to: contentView)
        self.leftSpacing.left(to: contentView, offset: 10)
        self.leftSpacing.bottomToTop(of: self.statusLabel)

        contentView.addLayoutGuide(self.rightSpacing)
        self.rightSpacing.top(to: contentView)
        self.rightSpacing.right(to: contentView, offset: -10)
        self.rightSpacing.bottomToTop(of: self.statusLabel)

        self.leftWidthSmall.isActive = false
        self.rightWidthBig.isActive = false
        self.leftWidthBig.isActive = true
        self.rightWidthSmall.isActive = true

        contentView.addSubview(self.container)
        self.container.top(to: contentView)
        self.container.leftToRight(of: self.leftSpacing)
        self.container.bottomToTop(of: self.statusLabel)
        self.container.rightToLeft(of: self.rightSpacing)

        contentView.addSubview(self.avatar)
        self.avatar.size(CGSize(width: 32, height: 32))
        self.avatar.bottomToTop(of: self.statusLabel)
        self.avatarLeft.isActive = true

        self.container.addSubview(self.imageView)
        self.imageView.top(to: self.container)
        self.imageView.left(to: self.container)
        self.imageView.right(to: self.container)

        self.container.addSubview(self.titleLabel)
        self.titleLabel.left(to: self.container, offset: self.horizontalMargin)
        self.titleLabel.right(to: self.container, offset: -self.horizontalMargin)

        self.container.addSubview(self.textLabel)
        self.textLeftConstraints.isActive = true
        self.textRightConstraints.isActive = true

        self.container.addSubview(self.subtitleLabel)
        self.subtitleLabel.left(to: self.container, offset: self.horizontalMargin)
        self.subtitleLabel.right(to: self.container, offset: -self.horizontalMargin)

        for button in buttons {
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            self.container.addSubview(button)
            button.left(to: container)
            button.right(to: container)
        }

        for guide in self.verticalGuides {
            self.container.addLayoutGuide(guide)
            guide.left(to: container)
            guide.right(to: container)
        }

        self.buttons[0].topToBottom(of: self.verticalGuides[3])
        self.buttons[0].bottomToTop(of: self.buttons[1])
        self.buttons[1].bottom(to: self.container)

        self.verticalGuides[0].topToBottom(of: self.imageView)
        self.verticalGuides[0].bottomToTop(of: self.titleLabel)
        self.verticalGuides[1].topToBottom(of: self.titleLabel)
        self.verticalGuides[1].bottomToTop(of: self.subtitleLabel)
        self.verticalGuides[2].topToBottom(of: self.subtitleLabel)
        self.verticalGuides[2].bottomToTop(of: self.textLabel)
        self.verticalGuides[3].topToBottom(of: self.textLabel)

        contentView.addLayoutGuide(self.bottomGuide)
        self.bottomGuide.topToBottom(of: self.statusLabel)
        self.bottomGuide.left(to: contentView)
        self.bottomGuide.bottom(to: contentView)
        self.bottomGuide.right(to: contentView)
    }

    func buttonPressed(_ button: MessageCellButton) {
        guard let model = button.model else { return }

        switch model.type {
        case .approve:
            self.delegate?.didTapApproveButton(self)
        case .decline:
            self.delegate?.didTapRejectButton(self)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        self.fixCorners()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        setNeedsLayout()
        layoutIfNeeded()
    }

    func fixCorners() {
        guard let message = message else { return }
        let corners: UIRectCorner = message.didSent ? [.bottomLeft, .topLeft, .topRight] : [.bottomRight, .topLeft, .topRight]

        self.container.roundCorners(corners, radius: 16)
        self.container.clipsToBounds = true
    }

    func size(for width: CGFloat) -> CGSize {
        guard let message = message else { return .zero }

        let maxWidth: CGFloat = width - 123
        var totalHeight: CGFloat = 0
        var totalMargin: CGFloat = 0

        if message.image != nil {
            totalHeight += 200
        }

        if let title = message.title, !title.isEmpty {
            totalHeight += title.height(withConstrainedWidth: maxWidth, font: titleFont)
            totalMargin += 10
        }

        if let subtitle = message.subtitle, !subtitle.isEmpty {
            totalHeight += subtitle.height(withConstrainedWidth: maxWidth, font: subtitleFont)
            totalMargin += 5
        }

        if let text = message.text, !text.isEmpty {
            totalHeight += text.height(withConstrainedWidth: maxWidth, font: textFont)
            totalMargin += 10
        }

        if let models = message.buttonModels {
            totalHeight += models[0].title.height(withConstrainedWidth: maxWidth, font: Theme.medium(size: 15)) + 30
            totalHeight += models[1].title.height(withConstrainedWidth: maxWidth, font: Theme.medium(size: 15)) + 30
        }

        var extraMargin: CGFloat = message.imageOnly ? 0 : 10

        if let text = message.text, text.hasEmojiOnly, text.characters.count < 4 {
            totalMargin = 0
            extraMargin = -14
        }

        var height = totalHeight + totalMargin + extraMargin

        if let status = message.status, message.type == .status, case .neutral(let s) = status {
            height = s.height(withConstrainedWidth: width, font: statusFont) + 20
        }

        return CGSize(width: ceil(width), height: ceil(height))
    }
}
