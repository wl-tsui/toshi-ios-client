import UIKit
import SweetUIKit

class ActionBarButton: UIControl {
    let imageView = UIImageView(withAutoLayout: true)

    let titleLabel = UILabel(withAutoLayout: true)

    private let imageContainerView = UIView(withAutoLayout: true)

    private var previousLabelTintColor: UIColor?
    private var previousImageTintColor: UIColor?

    override var tintColor: UIColor! {
        didSet {
            self.titleLabel.textColor = self.tintColor
            self.imageView.tintColor = self.tintColor
        }
    }

    init() {
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        self.titleLabel.textAlignment = .center
        self.titleLabel.font = Theme.medium(size: 14)

        self.imageContainerView.isUserInteractionEnabled = true
        self.imageView.isUserInteractionEnabled = true

        self.imageContainerView.addSubview(self.imageView)
        self.imageView.centerYAnchor.constraint(equalTo: self.imageContainerView.centerYAnchor).isActive = true
        self.imageView.centerXAnchor.constraint(equalTo: self.imageContainerView.centerXAnchor).isActive = true

        self.addSubview(self.imageContainerView)
        self.addSubview(self.titleLabel)

        self.titleLabel.set(height: 16)
        self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true

        self.imageContainerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.imageContainerView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.imageContainerView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.imageContainerView.bottomAnchor.constraint(equalTo: self.titleLabel.topAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func setTitle(_ title: String) {
        self.titleLabel.text = title
    }

    func setTitleColor(_ color: UIColor) {
        self.titleLabel.textColor = color
    }

    func setImage(_ image: UIImage) {
        self.imageView.image = image
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isHighlighted = true

        self.previousImageTintColor = self.imageView.tintColor
        self.previousLabelTintColor = self.titleLabel.tintColor

        self.imageView.tintColor = Theme.tintColor
        self.titleLabel.textColor = Theme.tintColor
        self.sendActions(for: .touchDown)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isHighlighted = false

        self.imageView.tintColor = self.previousImageTintColor
        self.titleLabel.textColor = self.previousLabelTintColor
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isHighlighted = false

        self.imageView.tintColor = self.previousImageTintColor
        self.titleLabel.textColor = self.previousLabelTintColor

        self.sendActions(for: .touchUpInside)
    }
}

class ContactActionView: UIStackView {

    lazy var messageButton: ActionBarButton = {
        let view = ActionBarButton()
        view.setImage(#imageLiteral(resourceName: "Message").withRenderingMode(.alwaysTemplate))
        view.setTitle("Message")
        view.tintColor = Theme.lightGreyTextColor

        return view
    }()

    lazy var addFavoriteButton: ActionBarButton = {
        let view = ActionBarButton()
        view.setImage(#imageLiteral(resourceName: "Favorites").withRenderingMode(.alwaysTemplate))
        view.setTitle("Favorite")
        view.tintColor = Theme.lightGreyTextColor

        return view
    }()

    lazy var payButton: ActionBarButton = {
        let view = ActionBarButton()
        view.setImage(#imageLiteral(resourceName: "Pay").withRenderingMode(.alwaysTemplate))
        view.setTitle("Pay")
        view.tintColor = Theme.lightGreyTextColor

        return view
    }()

    convenience init() {
        self.init(arrangedSubviews: [])

        self.distribution = .equalSpacing
        self.isLayoutMarginsRelativeArrangement = true
        self.layoutMargins.left = 38
        self.layoutMargins.right = 38

        self.insertArrangedSubview(self.messageButton, at: 0)
        self.insertArrangedSubview(self.addFavoriteButton, at: 1)
        self.insertArrangedSubview(self.payButton, at: 2)

        self.translatesAutoresizingMaskIntoConstraints = false

        self.messageButton.widthAnchor.constraint(equalTo: self.addFavoriteButton.widthAnchor).isActive = true
        self.addFavoriteButton.widthAnchor.constraint(equalTo: self.payButton.widthAnchor).isActive = true
    }
}
