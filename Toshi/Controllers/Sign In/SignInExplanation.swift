import Foundation
import UIKit
import TinyConstraints

final class SignInExplanationViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = Localized.passphrase_sign_in_explanation_title
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredTitle1()
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 0
        
        return view
    }()

    private lazy var textLabel: UILabel = {
        let attributedText = NSMutableAttributedString(string: Localized.passphrase_sign_in_explanation_text, attributes: [.font: Theme.preferredRegularMedium(), .foregroundColor: Theme.darkTextColor])

        if let firstParagraph = attributedText.string.components(separatedBy: "\n\n").first, let range = (attributedText.string as NSString?)?.range(of: firstParagraph) {
            attributedText.addAttribute(.font, value: Theme.semibold(size: 16), range: range)
        }

        let view = UILabel()
        view.numberOfLines = 0
        view.attributedText = attributedText
        view.adjustsFontForContentSizeCategory = true
        view.accessibilityIdentifier = AccessibilityIdentifier.passphraseSignInExplanationLabel.rawValue

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 22
        view.addSubview(stackView)

        stackView.top(to: layoutGuide())
        stackView.leftToSuperview(offset: .largeInterItemSpacing)
        stackView.rightToSuperview(offset: .largeInterItemSpacing)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textLabel)
    }
}
