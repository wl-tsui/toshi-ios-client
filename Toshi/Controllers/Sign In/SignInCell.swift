import Foundation
import UIKit
import TinyConstraints

final class SignInCell: UICollectionViewCell {

    static let reuseIdentifier: String = "SignInCell"
    private(set) var text: String = ""
    private(set) var match: String?
    private(set) var isFirstAndOnly: Bool = false
    private var cursorViewLeftConstraint: NSLayoutConstraint?
    private var cursorViewRightConstraint: NSLayoutConstraint?
    private let cursorKerning: CGFloat = 1

    private lazy var backgroundImageView = UIImageView(image: ImageAsset.sign_in_cell_background.stretchableImage(withLeftCapWidth: 18, topCapHeight: 18))
    private lazy var passwordLabel: UILabel = {
        let view = UILabel()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private(set) var cursorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor
        view.layer.cornerRadius = 1
        view.clipsToBounds = true

        return view
    }()

    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            self.isActive = isSelected
        }
    }

    var isActive: Bool = false {
        didSet {
            cursorView.alpha = isActive ? 1 : 0
            backgroundImageView.isHidden = isActive

            if let match = match, !isActive {
                updateAttributedText(match, with: match)

                contentView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)

                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 100, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.contentView.transform = .identity
                }, completion: nil)

            } else {
                updateAttributedText(text, with: match)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = nil
        contentView.isOpaque = false

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(passwordLabel)
        passwordLabel.addSubview(cursorView)

        backgroundImageView.edges(to: contentView)
        backgroundImageView.height(36, relation: .equalOrGreater)
        backgroundImageView.width(36, relation: .equalOrGreater)

        passwordLabel.edges(to: contentView, insets: UIEdgeInsets(top: 2, left: 13 + cursorKerning, bottom: -4, right: -13))

        cursorViewLeftConstraint = cursorView.left(to: passwordLabel)
        cursorViewRightConstraint = cursorView.right(to: passwordLabel, isActive: false)
        cursorView.centerY(to: passwordLabel)
        cursorView.width(2)
        cursorView.height(21)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.cursorView.isHidden = !self.cursorView.isHidden
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String, with match: String? = nil, isFirstAndOnly: Bool = false) {
        self.text = text
        self.match = match
        self.isFirstAndOnly = isFirstAndOnly

        updateAttributedText(text, with: match)
    }

    func updateAttributedText(_ text: String, with match: String? = nil) {
        let emptyString = isFirstAndOnly ? Localized.passphrase_sign_in_placeholder : ""
        let string = text.isEmpty ? emptyString : match ?? text
        let attributedText = NSMutableAttributedString(string: string, attributes: [.font: Theme.preferredRegular(), .foregroundColor: Theme.greyTextColor])

        if let match = match, let matchingRange = (match as NSString?)?.range(of: text, options: [.caseInsensitive, .anchored]) {
            attributedText.addAttribute(.foregroundColor, value: Theme.darkTextColor, range: matchingRange)
            attributedText.addAttribute(.kern, value: cursorKerning, range: NSRange(location: matchingRange.length - 1, length: 1))

            cursorViewRightConstraint?.isActive = false
            cursorViewLeftConstraint?.isActive = true
            cursorViewLeftConstraint?.constant = round(matchingFrame(for: matchingRange, in: attributedText).width) - cursorKerning - 1
        } else if text.isEmpty {
            cursorViewRightConstraint?.isActive = false
            cursorViewLeftConstraint?.isActive = true
            cursorViewLeftConstraint?.constant = 0
        } else {
            let errorRange = NSRange(location: 0, length: attributedText.length)
            attributedText.addAttribute(.foregroundColor, value: Theme.errorColor, range: errorRange)

            cursorViewLeftConstraint?.isActive = false
            cursorViewRightConstraint?.isActive = true
        }

        passwordLabel.attributedText = attributedText
    }

    private func matchingFrame(for range: NSRange, in attributedText: NSAttributedString) -> CGRect {
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: passwordLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()

        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
