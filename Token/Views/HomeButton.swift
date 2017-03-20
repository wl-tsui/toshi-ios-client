import UIKit
import SweetUIKit

class HomeButton: UIControl {

    private lazy var imageContainerView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)

        view.addSubview(self.imageView)

        self.imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var subtitle: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        view.font = Theme.semibold(size: 15)
        view.textColor = Theme.darkTextColor
        view.highlightedTextColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.allowsDefaultTighteningForTruncation = true

        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            self.imageView.isHighlighted = self.isHighlighted
            self.subtitle.isHighlighted = self.isHighlighted
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.imageContainerView)
        self.addSubview(self.subtitle)

        self.imageContainerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.imageContainerView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.imageContainerView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.imageContainerView.bottomAnchor.constraint(equalTo: self.subtitle.topAnchor).isActive = true

        self.subtitle.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.subtitle.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.subtitle.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func setImage(_ image: UIImage) {
        self.imageView.image = image
        self.imageView.highlightedImage = image.colored(with: UIColor.black.withAlphaComponent(0.2))
    }

    func setSubtitle(_ text: String) {
        self.subtitle.text = text
    }
}
