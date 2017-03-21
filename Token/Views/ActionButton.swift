import UIKit
import SweetUIKit

class ActionButton: UIControl {

    private lazy var background: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var backgroundOverlay: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isUserInteractionEnabled = false
        view.alpha = 0

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.lightTextColor
        view.textAlignment = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    var title: String? {
        didSet {
            guard let title = self.title else { return }
            self.titleLabel.text = title
        }
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.background)
        self.background.addSubview(self.backgroundOverlay)
        self.addSubview(self.titleLabel)

        NSLayoutConstraint.activate([
            self.background.topAnchor.constraint(equalTo: self.topAnchor),
            self.background.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.background.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.background.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.backgroundOverlay.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundOverlay.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundOverlay.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 30),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -30),

            self.heightAnchor.constraint(equalToConstant: 44).priority(.high),
            self.widthAnchor.constraint(greaterThanOrEqualToConstant: 160).priority(.high),
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted != oldValue {
                self.feedbackGenerator.impactOccurred()

                UIView.highlightAnimation {
                    self.backgroundOverlay.alpha = self.isHighlighted ? 1 : 0
                }
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            UIView.highlightAnimation {
                self.background.backgroundColor = self.isEnabled ? Theme.tintColor : Theme.greyTextColor
                self.alpha = self.isEnabled ? 1 : 0.6
            }
        }
    }
}
