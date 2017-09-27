import Foundation
import UIKit
import TinyConstraints

final class SignInExplanationViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = Localized("passphrase_sign_in_explanation_title")
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 34)
        view.numberOfLines = 0

        return view
    }()

    private lazy var textLabel: UILabel = {
        let attributedText = NSMutableAttributedString(string: Localized("passphrase_sign_in_explanation_text"), attributes: [.font: Theme.regular(size: 16), .foregroundColor: Theme.darkTextColor])

        if let firstParagraph = attributedText.string.components(separatedBy: "\n\n").first, let range = (attributedText.string as NSString?)?.range(of: firstParagraph) {
            attributedText.addAttribute(.font, value: Theme.semibold(size: 16), range: range)
        }

        let view = UILabel()
        view.numberOfLines = 0
        view.attributedText = attributedText

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor

        view.addSubview(titleLabel)
        view.addSubview(textLabel)

        titleLabel.top(to: view, offset: 64)
        titleLabel.left(to: view, offset: 20)
        titleLabel.right(to: view, offset: -20)

        textLabel.topToBottom(of: titleLabel, offset: 22)
        textLabel.left(to: view, offset: 20)
        textLabel.right(to: view, offset: -20)
    }
}
