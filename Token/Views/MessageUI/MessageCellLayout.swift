import NoChat
import YYText

class ActionableMessageCellLayout: MessageCellLayout {

    var attributedTitle: NSAttributedString? {
        return self.message.attributedTitle
    }

    var attributedSubtitle: NSAttributedString? {
        return self.message.attributedSubtitle
    }

    var subtitleLabelFrame: CGRect = .zero
    var titleLabelFrame: CGRect = .zero

    var rejectButtonFrame: CGRect = .zero
    var acceptButtonFrame: CGRect = .zero

    required init(chatItem: NOCChatItem, cellWidth width: CGFloat) {
        super.init(chatItem: chatItem, cellWidth: width)

        self.reuseIdentifier = "TGActionableTextMessageCell"
    }

    override func calculate() {
        self.height = 0
        self.titleLabelFrame = .zero
        self.subtitleLabelFrame = .zero
        self.rejectButtonFrame = .zero
        self.acceptButtonFrame = .zero
        self.bubbleViewFrame = .zero
        self.bubbleImageViewFrame = .zero
        self.textLabelFrame = .zero
        self.textLayout = nil
        self.timeLabelFrame = .zero
        self.deliveryStatusViewFrame = .zero

        guard let text = self.attributedText, text.length > 0, let time = self.attributedTime else {
            return
        }

        // dynamic font support
        let dynamicFont = Style.textFont
        text.yy_setAttribute(NSFontAttributeName, value: dynamicFont)

        let preferredMaxBubbleWidth = ceil(width * 0.75)
        var bubbleViewWidth = preferredMaxBubbleWidth

        // prelayout
        let unlimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let timeLabelSize = time.boundingRect(with: unlimitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
        let timeLabelWidth = timeLabelSize.width
        let timeLabelHeight = CGFloat(15)

        let deliveryStatusWidth: CGFloat = (self.isOutgoing && self.message.deliveryStatus != .unsent) ? 15 : 0
        let deliveryStatusHeight = deliveryStatusWidth

        let hPadding = CGFloat(8)
        let vPadding = CGFloat(4)

        let textMargin = self.isOutgoing ? UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 15) : UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 10)
        var textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right - hPadding - timeLabelWidth - hPadding / 2 - deliveryStatusWidth

        let modifier = TGTextLinePositionModifier()
        modifier.font = dynamicFont
        modifier.paddingTop = 2
        modifier.paddingBottom = 2

        let container = YYTextContainer()
        container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)
        container.linePositionModifier = modifier

        guard let textLayout = YYTextLayout(container: container, text: text) else {
            return
        }

        self.textLayout = textLayout

        var bubbleViewHeight = CGFloat(0)

        // relayout
        if textLayout.rowCount > 1 {
            textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right
            container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)

            guard let newTextLayout = YYTextLayout(container: container, text: text) else {
                return
            }

            self.textLayout = newTextLayout

            // layout content in bubble
            textLabelWidth = ceil(newTextLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: newTextLayout.rowCount))

            self.textLabelFrame = CGRect(x: textMargin.left, y: textMargin.top, width: textLabelWidth, height: textLabelHeight)

            let tryPoint = CGPoint(x: textLabelWidth - deliveryStatusWidth - hPadding / 2 - timeLabelWidth - hPadding, y: textLabelHeight - timeLabelHeight / 2)

            let needNewLine = newTextLayout.textRange(at: tryPoint) != nil
            if needNewLine {
                var x = bubbleViewWidth - textMargin.left - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                var y = textMargin.top + textLabelHeight

                y += vPadding
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)

                bubbleViewHeight = textMargin.top + textLabelHeight + vPadding + timeLabelHeight + textMargin.bottom
                self.bubbleViewFrame = self.isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            } else {
                bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
                self.bubbleViewFrame = self.isOutgoing ? CGRect(x: self.width - self.bubbleViewMargin.right - bubbleViewWidth, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: self.bubbleViewMargin.left, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

                var x = bubbleViewWidth - textMargin.right - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                let y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
            }

        } else {
            textLabelWidth = ceil(textLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: textLayout.rowCount))

            bubbleViewWidth = textMargin.left + textLabelWidth + hPadding + timeLabelWidth + hPadding / 2 + deliveryStatusWidth + textMargin.right
            bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
            self.bubbleViewFrame = self.isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

            self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            var x = textMargin.left
            var y = textMargin.top
            self.textLabelFrame = CGRect(x: x, y: y, width: textLabelWidth, height: textLabelHeight)

            x += textLabelWidth + hPadding
            y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
            self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

            x += timeLabelWidth + hPadding / 2
            self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
        }

        if let attributedTitle = self.attributedTitle {
            let size = attributedTitle.boundingRect(with: CGSize(width: textLabelWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            self.titleLabelFrame = CGRect(x: self.textLabelFrame.origin.x, y: textMargin.top, width: size.width, height: size.height)

            let diff = self.titleLabelFrame.height + textMargin.top

            bubbleViewHeight += diff
            self.textLabelFrame.origin.y += diff
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.height = bubbleViewHeight
        }

        if let attributedSubtitle = self.attributedSubtitle {
            let size = attributedSubtitle.boundingRect(with: CGSize(width: textLabelWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            let top = textMargin.top + self.titleLabelFrame.maxY
            self.subtitleLabelFrame = CGRect(x: self.textLabelFrame.origin.x, y: top, width: size.width, height: size.height)

            let diff = self.subtitleLabelFrame.height + textMargin.top

            bubbleViewHeight += diff
            self.textLabelFrame.origin.y += diff
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.height = bubbleViewHeight
        }

        if let item = self.chatItem as? Message, item.isActionable {
            let height: CGFloat = 44.0
            let x: CGFloat = 4.0
            let buttonWidth = (self.bubbleImageViewFrame.width / 2) - 2

            self.rejectButtonFrame = CGRect(x: x, y: bubbleViewHeight, width: buttonWidth, height: height)
            self.acceptButtonFrame = CGRect(x: x + buttonWidth - 1, y: bubbleViewHeight, width: buttonWidth, height: height)

            bubbleViewHeight += self.rejectButtonFrame.height
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.height = bubbleViewHeight
        }

        self.height = bubbleViewHeight + self.bubbleViewMargin.top + self.bubbleViewMargin.bottom
    }
}

class MessageCellLayout: TGBaseMessageCellLayout {

    var attributedTime: NSAttributedString?
    var bubbleImage: UIImage?
    var highlightBubbleImage: UIImage?

    var bubbleImageViewFrame = CGRect.zero
    var textLabelFrame = CGRect.zero
    var textLayout: YYTextLayout?
    var timeLabelFrame = CGRect.zero
    var deliveryStatusViewFrame = CGRect.zero

    var attributedText: NSMutableAttributedString?

    required init(chatItem: NOCChatItem, cellWidth width: CGFloat) {
        super.init(chatItem: chatItem, cellWidth: width)

        self.reuseIdentifier = "TGTextMessageCell"

        self.setupAttributedText()
        self.setupAttributedTime()
        self.setupBubbleImage()
        self.calculate()
    }

    private func setupAttributedText() {
        let text = self.message.text
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: Style.textFont, NSForegroundColorAttributeName: self.isOutgoing ? Theme.outgoingMessageTextColor : Theme.incomingMessageTextColor])

        if text == "/start" {
            attributedText.yy_setColor(Style.linkColor, range: attributedText.yy_rangeOfAll())

            let highlightBorder = YYTextBorder()
            highlightBorder.insets = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
            highlightBorder.cornerRadius = 2
            highlightBorder.fillColor = Style.linkBackgroundColor

            let highlight = YYTextHighlight()
            highlight.setBackgroundBorder(highlightBorder)
            highlight.userInfo = ["command": text]

            attributedText.yy_setTextHighlight(highlight, range: attributedText.yy_rangeOfAll())
        }

        self.attributedText = attributedText
    }

    private func setupAttributedTime() {
        let timeString = Style.timeFormatter.string(from: message.date)
        let timeColor = self.isOutgoing ? Style.outgoingTimeColor : Style.incomingTimeColor
        self.attributedTime = NSAttributedString(string: timeString, attributes: [NSFontAttributeName: Style.timeFont, NSForegroundColorAttributeName: timeColor])
    }

    private func setupBubbleImage() {
        self.bubbleImage = self.isOutgoing ? Style.outgoingBubbleImage : Style.incomingBubbleImage

        self.highlightBubbleImage = self.isOutgoing ? Style.highlightOutgoingBubbleImage : Style.highlightIncomingBubbleImage
    }

    override func calculate() {
        self.height = 0
        self.bubbleViewFrame = CGRect.zero
        self.bubbleImageViewFrame = CGRect.zero
        self.textLabelFrame = CGRect.zero
        self.textLayout = nil
        self.timeLabelFrame = CGRect.zero
        self.deliveryStatusViewFrame = CGRect.zero

        guard let text = self.attributedText, text.length > 0, let time = self.attributedTime else {
            return
        }

        // dynamic font support
        let dynamicFont = Style.textFont
        text.yy_setAttribute(NSFontAttributeName, value: dynamicFont)

        let preferredMaxBubbleWidth = ceil(width * 0.75)
        var bubbleViewWidth = preferredMaxBubbleWidth

        // prelayout
        let unlimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let timeLabelSize = time.boundingRect(with: unlimitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
        let timeLabelWidth = timeLabelSize.width
        let timeLabelHeight = CGFloat(15)

        let deliveryStatusWidth: CGFloat = (self.isOutgoing && self.message.deliveryStatus != .unsent) ? 15 : 0
        let deliveryStatusHeight = deliveryStatusWidth

        let hPadding = CGFloat(8)
        let vPadding = CGFloat(4)

        let textMargin = self.isOutgoing ? UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 15) : UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 10)
        var textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right - hPadding - timeLabelWidth - hPadding / 2 - deliveryStatusWidth

        let modifier = TGTextLinePositionModifier()
        modifier.font = dynamicFont
        modifier.paddingTop = 2
        modifier.paddingBottom = 2

        let container = YYTextContainer()
        container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)
        container.linePositionModifier = modifier

        guard let textLayout = YYTextLayout(container: container, text: text) else {
            return
        }

        self.textLayout = textLayout

        var bubbleViewHeight = CGFloat(0)

        // relayout
        if textLayout.rowCount > 1 {
            textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right
            container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)

            guard let newTextLayout = YYTextLayout(container: container, text: text) else {
                return
            }

            self.textLayout = newTextLayout

            // layout content in bubble
            textLabelWidth = ceil(newTextLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: newTextLayout.rowCount))

            self.textLabelFrame = CGRect(x: textMargin.left, y: textMargin.top, width: textLabelWidth, height: textLabelHeight)

            let tryPoint = CGPoint(x: textLabelWidth - deliveryStatusWidth - hPadding / 2 - timeLabelWidth - hPadding, y: textLabelHeight - timeLabelHeight / 2)

            let needNewLine = newTextLayout.textRange(at: tryPoint) != nil
            if needNewLine {
                var x = bubbleViewWidth - textMargin.left - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                var y = textMargin.top + textLabelHeight

                y += vPadding
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)

                bubbleViewHeight = textMargin.top + textLabelHeight + vPadding + timeLabelHeight + textMargin.bottom
                self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            } else {
                bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
                self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

                var x = bubbleViewWidth - textMargin.right - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                let y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
            }

        } else {
            textLabelWidth = ceil(textLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: textLayout.rowCount))

            bubbleViewWidth = textMargin.left + textLabelWidth + hPadding + timeLabelWidth + hPadding / 2 + deliveryStatusWidth + textMargin.right
            bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
            self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

            self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            var x = textMargin.left
            var y = textMargin.top
            self.textLabelFrame = CGRect(x: x, y: y, width: textLabelWidth, height: textLabelHeight)

            x += textLabelWidth + hPadding
            y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
            self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

            x += timeLabelWidth + hPadding / 2
            self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
        }

        self.height = bubbleViewHeight + self.bubbleViewMargin.top + self.bubbleViewMargin.bottom
    }

    struct Style {
        static let outgoingBubbleImage = #imageLiteral(resourceName: "TGBubbleOutgoing").withRenderingMode(.alwaysTemplate)
        static let highlightOutgoingBubbleImage = #imageLiteral(resourceName: "TGBubbleOutgoingHL").withRenderingMode(.alwaysTemplate)

        static let incomingBubbleImage = #imageLiteral(resourceName: "TGBubbleIncoming").withRenderingMode(.alwaysTemplate)
        static let highlightIncomingBubbleImage = #imageLiteral(resourceName: "TGBubbleIncomingHL").withRenderingMode(.alwaysTemplate)

        static var textFont: UIFont {
            return Theme.medium(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
        }

        static let linkColor = UIColor(colorLiteralRed: 0 / 255.0, green: 75 / 255.0, blue: 173 / 255.0, alpha: 1)
        static let linkBackgroundColor = UIColor(colorLiteralRed: 191 / 255.0, green: 223 / 255.0, blue: 254 / 255.0, alpha: 1)

        static let timeFont = UIFont.systemFont(ofSize: 12)
        static let outgoingTimeColor = Theme.lightGreyTextColor
        static let incomingTimeColor = Theme.greyTextColor

        static let timeFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "h:mm a"
            return df
        }()
    }
}

fileprivate
class TGTextLinePositionModifier: NSObject, YYTextLinePositionModifier {

    var font = UIFont.systemFont(ofSize: 16)
    var paddingTop = CGFloat(0)
    var paddingBottom = CGFloat(0)
    var lineHeightMultiple = CGFloat(0)

    override init() {
        super.init()

        if #available(iOS 9.0, *) {
            self.lineHeightMultiple = 1.34 // for PingFang SC
        } else {
            self.lineHeightMultiple = 1.3125 // for Heiti SC
        }
    }

    fileprivate func modifyLines(_ lines: [YYTextLine], fromText text: NSAttributedString, in container: YYTextContainer) {
        let ascent = font.pointSize * 0.86

        let lineHeight = font.pointSize * lineHeightMultiple
        for line in lines {
            var position = line.position
            position.y = paddingTop + ascent + CGFloat(line.row) * lineHeight
            line.position = position
        }
    }

    fileprivate func copy(with zone: NSZone? = nil) -> Any {
        let one = TGTextLinePositionModifier()
        one.font = font
        one.paddingTop = paddingTop
        one.paddingBottom = paddingBottom
        one.lineHeightMultiple = lineHeightMultiple

        return one
    }

    fileprivate func height(forLineCount lineCount: UInt) -> CGFloat {
        if lineCount == 0 {
            return 0
        }

        let ascent = font.pointSize * 0.86
        let descent = font.pointSize * 0.14
        let lineHeight = font.pointSize * lineHeightMultiple

        return self.paddingTop + self.paddingBottom + ascent + descent + CGFloat(lineCount - 1) * lineHeight
    }
}
