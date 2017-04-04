import NoChat
import YYText

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
        self.bubbleView.addSubview(self.textLabel)
        self.bubbleImageView.addSubview(self.timeLabel)
        self.bubbleImageView.addSubview(self.deliveryStatusView)

        self.textLabel.textVerticalAlignment = .top
        self.textLabel.displaysAsynchronously = true
        self.textLabel.ignoreCommonProperties = true
        self.textLabel.fadeOnAsynchronouslyDisplay = false
        self.textLabel.fadeOnHighlight = false

        self.textLabel.highlightTapAction = { [weak self](_, text, range, _) -> Void in
            if range.location >= text.length { return }
            let highlight = text.yy_attribute(YYTextHighlightAttributeName, at: UInt(range.location)) as! YYTextHighlight
            guard let info = highlight.userInfo, info.count > 0 else { return }

            guard let strongSelf = self else { return }
            if let d = strongSelf.delegate as? TGTextMessageCellDelegate {
                d.didTapLink(cell: strongSelf, linkInfo: info)
            }
        }

        self.deliveryStatusView.clipsToBounds = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var layout: NOCChatItemCellLayout? {
        didSet {
            guard let cellLayout = self.layout as? MessageCellLayout else {
                fatalError("invalid layout type")
            }

            self.bubbleView.frame = cellLayout.bubbleViewFrame
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
