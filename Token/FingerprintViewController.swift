import UIKit

public class FingerprintViewController: UIViewController {
    var fingerprint: OWSFingerprint

    lazy var fingerprintQRImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)

        return view
    }()

    lazy var fingerprintNumberLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.numberOfLines = 0

        return label
    }()

    lazy var instructionsLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.numberOfLines = 0

        return label
    }()

    //    lazy var cameraButton: UIButton = {
    //        let button = UIButton(withAutoLayout: true)
    //
    //        return button
    //    }()

    public init(fingerprint: OWSFingerprint) {
        self.fingerprint = fingerprint

        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.viewBackgroundColor

        self.addSubviewsAndConstraints()

        self.fingerprintQRImageView.image = self.fingerprint.image
        self.fingerprintNumberLabel.text = self.fingerprint.displayableText

        self.instructionsLabel.text = "Change this text. Scan the code on your contact's device, or ask them to scan your code to verify that your messages are end-to-end encrypted."
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.fingerprintQRImageView)
        self.view.addSubview(self.fingerprintNumberLabel)
        self.view.addSubview(self.instructionsLabel)

        let margin: CGFloat = 22.0

        self.fingerprintQRImageView.set(height: 160)
        self.fingerprintQRImageView.set(width: 160)

        self.fingerprintQRImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: margin).isActive = true
        self.fingerprintQRImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.fingerprintNumberLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.fingerprintNumberLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        self.fingerprintNumberLabel.topAnchor.constraint(equalTo: self.fingerprintQRImageView.bottomAnchor, constant: margin).isActive = true
        self.fingerprintNumberLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.fingerprintNumberLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        self.instructionsLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.instructionsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        self.instructionsLabel.topAnchor.constraint(equalTo: self.fingerprintNumberLabel.bottomAnchor, constant: margin).isActive = true
        self.instructionsLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.instructionsLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true
        self.instructionsLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -margin).isActive = true
    }
}
