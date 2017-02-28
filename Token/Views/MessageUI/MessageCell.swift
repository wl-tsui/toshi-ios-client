import NoChat
import YYText

protocol ActionableCellDelegate {
    func didTapApproveButton(_ messageCell: ActionableMessageCell)

    func didTapRejectButton(_ messageCell: ActionableMessageCell)
}

class ActionableMessageCell: MessageCell {

    var actionsDelegate: ActionableCellDelegate?

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.adjustsFontSizeToFitWidth = true

        return view
    }()

    lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.adjustsFontSizeToFitWidth = true

        return view
    }()

    lazy var rejectButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapRejectButton), for: .touchUpInside)

        let title = NSAttributedString(string: "✕ Reject", attributes: [NSForegroundColorAttributeName: Theme.greyTextColor, NSFontAttributeName: Theme.regular(size: 16)])
        button.setAttributedTitle(title, for: .normal)

        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapAcceptButton), for: .touchUpInside)

        let title = NSAttributedString(string: "✓ Approve", attributes: [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.semibold(size: 16)])
        button.setAttributedTitle(title, for: .normal)

        return button
    }()

    override class func reuseIdentifier() -> String {
        return "TGActionableTextMessageCell"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.bubbleView.addSubview(self.titleLabel)
        self.bubbleView.addSubview(self.subtitleLabel)

        self.bubbleView.addSubview(self.rejectButton)
        self.bubbleView.addSubview(self.acceptButton)

        self.bubbleView.clipsToBounds = true
        self.timeLabel.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var layout: NOCChatItemCellLayout? {
        didSet {
            guard let cellLayout = self.layout as? ActionableMessageCellLayout else {
                fatalError("invalid layout type")
            }

            self.titleLabel.attributedText = cellLayout.attributedTitle
            self.subtitleLabel.attributedText = cellLayout.attributedSubtitle

            self.titleLabel.frame = cellLayout.titleLabelFrame
            self.subtitleLabel.frame = cellLayout.subtitleLabelFrame

            self.rejectButton.frame = cellLayout.rejectButtonFrame
            self.acceptButton.frame = cellLayout.acceptButtonFrame

            let rejectMask = CAShapeLayer()
            rejectMask.path = UIBezierPath(roundedRect: self.rejectButton.bounds, byRoundingCorners: UIRectCorner.bottomLeft, cornerRadii: CGSize(width: 20, height: 20)).cgPath
            self.rejectButton.layer.mask = rejectMask

            let acceptMask = CAShapeLayer()
            acceptMask.path = UIBezierPath(roundedRect: self.acceptButton.bounds, byRoundingCorners: UIRectCorner.bottomRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
            self.acceptButton.layer.mask = acceptMask
        }
    }

    func didTapRejectButton() {
        self.actionsDelegate?.didTapRejectButton(self)
    }

    func didTapAcceptButton() {
        self.actionsDelegate?.didTapApproveButton(self)
    }
}

class MessageCell: TGBaseMessageCell {

    var bubbleImageView = UIImageView()

    var textLabel = YYLabel()

    var timeLabel = UILabel()

    var deliveryStatusView = TGDeliveryStatusView()

    override class func reuseIdentifier() -> String {
        return "TGTextMessageCell"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.bubbleView.addSubview(self.bubbleImageView)

        self.textLabel.textVerticalAlignment = .top
        self.textLabel.displaysAsynchronously = true
        self.textLabel.ignoreCommonProperties = true
        self.textLabel.fadeOnAsynchronouslyDisplay = false
        self.textLabel.fadeOnHighlight = false

        self.textLabel.highlightTapAction = { [weak self](containerView, text, range, rect) -> Void in
            if range.location >= text.length { return }
            let highlight = text.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)) as! YYTextHighlight
            guard let info = highlight.userInfo, info.count > 0 else { return }

            guard let strongSelf = self else { return }
            if let d = strongSelf.delegate as? TGTextMessageCellDelegate {
                d.didTapLink(cell: strongSelf, linkInfo: info)
            }
        }

        self.deliveryStatusView.clipsToBounds = true

        self.bubbleView.addSubview(self.textLabel)
        self.bubbleImageView.addSubview(self.timeLabel)
        self.bubbleImageView.addSubview(self.deliveryStatusView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var layout: NOCChatItemCellLayout? {
        didSet {
            guard let cellLayout = self.layout as? MessageCellLayout else {
                fatalError("invalid layout type")
            }

            self.bubbleImageView.frame = cellLayout.bubbleImageViewFrame
            self.bubbleImageView.image = self.isHighlight ? cellLayout.highlightBubbleImage : cellLayout.bubbleImage

            self.bubbleImageView.tintColor = cellLayout.isOutgoing ? Theme.outgoingMessageBackgroundColor : Theme.incomingMessageBackgroundColor

            self.textLabel.frame = cellLayout.textLabelFrame
            self.textLabel.textLayout = cellLayout.textLayout

            self.timeLabel.frame = cellLayout.timeLabelFrame
            self.timeLabel.attributedText = cellLayout.attributedTime

            self.deliveryStatusView.frame = cellLayout.deliveryStatusViewFrame
            self.deliveryStatusView.deliveryStatus = cellLayout.message.deliveryStatus
            self.deliveryStatusView.tintColor = cellLayout.isOutgoing ? Theme.outgoingMessageTextColor : Theme.incomingMessageTextColor
        }
    }
}

protocol TGTextMessageCellDelegate: NOCChatItemCellDelegate {
    func didTapLink(cell: MessageCell, linkInfo: [AnyHashable: Any])
}
