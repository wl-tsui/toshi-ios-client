import Foundation
import UIKit
import TinyConstraints

final class SignInFooterView: UIView {

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()
    
    private lazy var errorLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isHidden = true
        
        return view
    }()
    
    private(set) lazy var signInButton: ActionButton = {
        let view = ActionButton(margin: 0)
        view.setButtonStyle(.primary)
        
        return view
    }()

    private(set) lazy var explanationButton: UIButton = {
        let view = UIButton()
        view.setTitle(Localized("passphrase_sign_in_explanation_title"), for: .normal)
        view.setTitleColor(Theme.greyTextColor, for: .normal)

        return view
    }()
    
    private var signInButtonTitle: String {
        
        let remaining = SignInViewController.maxItemCount - numberOfMatches
        
        switch remaining {
        case 0:
            return Localized("passphrase_sign_in_button")
        case 1:
            return String(format: Localized("passphrase_sign_in_button_placeholder_singular"), remaining)
        default:
            return String(format: Localized("passphrase_sign_in_button_placeholder"), remaining)
        }
    }
    
    var numberOfMatches: Int = 0 {
        didSet {
            signInButton.title = signInButtonTitle
            signInButton.isEnabled = numberOfMatches == SignInViewController.maxItemCount
        }
    }
    
    var numberOfErrors: Int = 0 {
        didSet {
            guard numberOfErrors != oldValue else { return  }
            let errorMessage: String
            
            switch numberOfErrors {
            case 0:
                errorMessage = ""
                errorLabel.isHidden = true
                errorLabelTopConstraint?.isActive = false
                signInButtonTopConstraint?.isActive = true
                return
            case 1:
                errorMessage = Localized("passphrase_sign_in_error_singular")
            default:
                errorMessage = Localized("passphrase_sign_in_error")
            }
            
            errorLabel.isHidden = false
            signInButtonTopConstraint?.isActive = false
            errorLabelTopConstraint?.isActive = true
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedStringKey: Any] = [
                .font: Theme.regular(size: 13),
                .foregroundColor: Theme.errorColor,
                .paragraphStyle: paragraphStyle
            ]
            
            errorLabel.attributedText = NSMutableAttributedString(string: String(format: errorMessage, numberOfErrors), attributes: attributes)
        }
    }
    
    var signInButtonTopConstraint: NSLayoutConstraint?
    var errorLabelTopConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(divider)
        addSubview(signInButton)
        addSubview(errorLabel)
        addSubview(explanationButton)

        divider.top(to: self)
        divider.left(to: self, offset: 30)
        divider.right(to: self, offset: -30)
        divider.height(1)

        signInButtonTopConstraint = signInButton.topToBottom(of: divider, offset: 30)
        signInButton.left(to: self, offset: 30)
        signInButton.right(to: self, offset: -30)
        signInButton.heightConstraint.constant = 50
        
        errorLabelTopConstraint = errorLabel.topToBottom(of: divider, offset: 15, isActive: false)
        errorLabel.left(to: self, offset: 30)
        errorLabel.right(to: self, offset: -30)
        errorLabel.bottomToTop(of: signInButton, offset: -15)

        explanationButton.topToBottom(of: signInButton, offset: 5)
        explanationButton.left(to: self, offset: 30)
        explanationButton.right(to: self, offset: -30)
        explanationButton.bottom(to: self)
        explanationButton.height(50)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
