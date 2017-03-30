import NoChat
import UIKit
import HPGrowingTextView
import SweetUIKit

protocol ChatInputTextPanelDelegate: NOCChatInputPanelDelegate {
    func inputTextPanel(_ inputTextPanel: ChatInputTextPanel, requestSendText text: String)
    func keyboardMoved(with offset: CGFloat)
}

class ChatInputTextPanel: NOCChatInputPanel {

    static let defaultHeight: CGFloat = 51

    fileprivate let inputContainerInsets = UIEdgeInsets(top: 8, left: 41, bottom: 7, right: 0)
    fileprivate let maximumInputContainerHeight: CGFloat = 175

    fileprivate var inputContainerHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if inputContainerHeight != oldValue {
                invalidateLayout()
            }
        }
    }

    fileprivate func inputContainerHeight(for textViewHeight: CGFloat) -> CGFloat {
        return min(self.maximumInputContainerHeight, max(ChatInputTextPanel.defaultHeight, textViewHeight + self.inputContainerInsets.top + self.inputContainerInsets.bottom))
    }

    var buttonsHeight: CGFloat = 0 {
        didSet {
            if buttonsHeight != oldValue {
                negativeSpaceConstraint.constant = buttonsHeight
                invalidateLayout()
            }
        }
    }

    lazy var negativeSpaceConstraint: NSLayoutConstraint = {
        self.negativeSpace.heightAnchor.constraint(equalToConstant: 0)
    }()

    lazy var negativeSpace: UILayoutGuide = {
        UILayoutGuide()
    }()

    lazy var inputContainer: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.inputFieldBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight

        return view
    }()

    lazy var inputField: HPGrowingTextView = {
        let view = HPGrowingTextView(withAutoLayout: true)
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = (ChatInputTextPanel.defaultHeight - (self.inputContainerInsets.top + self.inputContainerInsets.bottom)) / 2
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight
        view.delegate = self
        view.font = UIFont.systemFont(ofSize: 16)
        view.internalTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        view.internalTextView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 5)

        return view
    }()

    fileprivate lazy var attachButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "TGAttachButton").withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = Theme.tintColor
        view.contentMode = .center

        return view
    }()

    fileprivate lazy var sendButton: ActionButton = {
        let view = ActionButton(margin: 0)
        view.title = "Send"
        view.style = .plain
        view.titleLabel.font = Theme.semibold(size: 16)
        view.heightConstraint.constant = ChatInputTextPanel.defaultHeight
        view.isEnabled = false
        view.addTarget(self, action: #selector(send(_:)), for: .touchUpInside)

        return view
    }()

    public var text: String? {
        get {
            return inputField.text
        } set {
            self.inputField.text = newValue ?? ""
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addLayoutGuide(negativeSpace)
        addSubview(inputContainer)
        addSubview(attachButton)
        addSubview(inputField)
        addSubview(sendButton)

        NSLayoutConstraint.activate([
            negativeSpace.topAnchor.constraint(equalTo: topAnchor),
            negativeSpace.leftAnchor.constraint(equalTo: leftAnchor),
            negativeSpace.rightAnchor.constraint(equalTo: rightAnchor),
            negativeSpaceConstraint,

            attachButton.leftAnchor.constraint(equalTo: leftAnchor),
            attachButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            attachButton.rightAnchor.constraint(equalTo: inputField.leftAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 51),
            attachButton.heightAnchor.constraint(equalToConstant: 51),

            inputContainer.topAnchor.constraint(equalTo: negativeSpace.bottomAnchor),
            inputContainer.leftAnchor.constraint(equalTo: leftAnchor, constant: -1),
            inputContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            inputContainer.rightAnchor.constraint(equalTo: rightAnchor, constant: 1),

            inputField.topAnchor.constraint(equalTo: negativeSpace.bottomAnchor, constant: inputContainerInsets.top),
            inputField.leftAnchor.constraint(equalTo: attachButton.rightAnchor),
            inputField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inputContainerInsets.bottom),

            sendButton.leftAnchor.constraint(equalTo: inputField.rightAnchor),
            sendButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            sendButton.rightAnchor.constraint(equalTo: rightAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 70),
        ])
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        if self.point(inside: point, with: event) {

            for subview in subviews.reversed() {
                let point = subview.convert(point, from: self)

                if let hitTestView = subview.hitTest(point, with: event) {
                    return hitTestView
                }
            }

            return nil
        }

        return nil
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: inputContainerHeight + buttonsHeight)
    }

    func textViewDidChange(_: UITextView) {
        invalidateLayout()
    }

    func invalidateLayout() {
        if frame.isEmpty { return }
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    func send(_: ActionButton) {
        guard let text = inputField.text, text.characters.count > 0 else { return }

        let string = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.characters.count > 0 {
            if let delegate = delegate as? ChatInputTextPanelDelegate {
                delegate.inputTextPanel(self, requestSendText: string)
            }
        }

        self.text = nil
        sendButton.isEnabled = false
        invalidateLayout()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        superview?.removeObserver(self, forKeyPath: #keyPath(center))
        newSuperview?.addObserver(self, forKeyPath: #keyPath(center), options: [], context: nil)
        super.willMove(toSuperview: newSuperview)

        invalidateLayout()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        invalidateLayout()
    }

    override func observeValue(forKeyPath keyPath: String?, of _: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {

        if let superview = superview, keyPath == #keyPath(center) {
            offset = UIScreen.main.bounds.height - superview.center.y + (superview.bounds.height / 2)
        }
    }

    private var offset: CGFloat = 0 {
        didSet {
            if offset != oldValue, let delegate = delegate as? ChatInputTextPanelDelegate {
                delegate.keyboardMoved(with: offset)
            }
        }
    }
}

extension ChatInputTextPanel: HPGrowingTextViewDelegate {

    func growingTextView(_ textView: HPGrowingTextView!, willChangeHeight _: Float) {
        inputContainerHeight = inputContainerHeight(for: textView.frame.height)
    }

    func growingTextViewDidChange(_ textView: HPGrowingTextView!) {
        sendButton.isEnabled = inputField.internalTextView.hasText
        inputContainerHeight = inputContainerHeight(for: textView.frame.height)
    }
}
