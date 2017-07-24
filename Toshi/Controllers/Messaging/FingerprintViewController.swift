// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor

        addSubviewsAndConstraints()

        fingerprintQRImageView.image = fingerprint.image
        fingerprintNumberLabel.text = fingerprint.displayableText

        instructionsLabel.text = "Change this text. Scan the code on your contact's device, or ask them to scan your code to verify that your messages are end-to-end encrypted."
    }

    func addSubviewsAndConstraints() {
        view.addSubview(fingerprintQRImageView)
        view.addSubview(fingerprintNumberLabel)
        view.addSubview(instructionsLabel)

        let margin: CGFloat = 22.0

        fingerprintQRImageView.set(height: 160)
        fingerprintQRImageView.set(width: 160)

        fingerprintQRImageView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: margin).isActive = true
        fingerprintQRImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        fingerprintNumberLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        fingerprintNumberLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        fingerprintNumberLabel.topAnchor.constraint(equalTo: fingerprintQRImageView.bottomAnchor, constant: margin).isActive = true
        fingerprintNumberLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        fingerprintNumberLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true

        instructionsLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        instructionsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        instructionsLabel.topAnchor.constraint(equalTo: fingerprintNumberLabel.bottomAnchor, constant: margin).isActive = true
        instructionsLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        instructionsLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true
        instructionsLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin).isActive = true
    }
}
