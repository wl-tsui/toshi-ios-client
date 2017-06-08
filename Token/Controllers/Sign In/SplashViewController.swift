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

import Foundation
import UIKit
import SweetUIKit

let logoTopSpace: CGFloat = 100.0
let logoSize: CGFloat = 54.0

let titleLabelToSpace: CGFloat = 27.0

final class SplashViewController: UIViewController {

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "splash")

        return imageView
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .center
        imageView.image = UIImage(named: "logo")

        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 43.0)
        label.textAlignment = .center
        label.textColor = Theme.viewBackgroundColor
        label.numberOfLines = 0
        label.text = "Welcome to\nToken"

        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 17.0)
        label.textColor = Theme.viewBackgroundColor.withAlphaComponent(0.6)
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center

        let attrString = NSMutableAttributedString(string: "A browser for the Ethereum network\nthat provides universal access to\nfinancial services")
        attrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attrString.length))

        label.attributedText = attrString

        return label
    }()

    private lazy var signinButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.isUserInteractionEnabled = true
        button.setTitle("Sign in", for: .normal)
        button.setTitleColor(Theme.viewBackgroundColor, for: .normal)
        button.addTarget(self, action: #selector(signinPressed(_:)), for: .touchUpInside)
        button.titleLabel?.font = Theme.regular(size: 16.0)

        return button
    }()

    private lazy var newAccountButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.setTitle("Create a new account", for: .normal)
        button.setTitleColor(Theme.viewBackgroundColor, for: .normal)
        button.addTarget(self, action: #selector(newAccountPressed(_:)), for: .touchUpInside)
        button.titleLabel?.font = Theme.regular(size: 20.0)

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.decorateView()
    }

    private func decorateView() {
        self.view.addSubview(self.backgroundImageView)
        self.backgroundImageView.fillSuperview()

        self.backgroundImageView.addSubview(self.logoImageView)
        self.logoImageView.topAnchor.constraint(equalTo: self.backgroundImageView.topAnchor, constant: logoTopSpace).isActive = true
        self.logoImageView.centerXAnchor.constraint(equalTo: self.backgroundImageView.centerXAnchor).isActive = true
        self.logoImageView.set(height: logoSize)
        self.logoImageView.set(width: logoSize)

        self.backgroundImageView.addSubview(self.titleLabel)
        self.titleLabel.topAnchor.constraint(equalTo: self.logoImageView.bottomAnchor, constant: 24.0).isActive = true
        self.titleLabel.centerXAnchor.constraint(equalTo: self.backgroundImageView.centerXAnchor).isActive = true

        self.backgroundImageView.addSubview(self.subtitleLabel)
        self.subtitleLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20.0).isActive = true
        self.subtitleLabel.centerXAnchor.constraint(equalTo: self.backgroundImageView.centerXAnchor).isActive = true

        self.backgroundImageView.addSubview(self.signinButton)
        self.signinButton.set(width: 70.0)
        self.signinButton.set(height: 44.0)
        self.signinButton.centerXAnchor.constraint(equalTo: self.backgroundImageView.centerXAnchor).isActive = true
        self.signinButton.bottomAnchor.constraint(equalTo: self.backgroundImageView.bottomAnchor, constant: -40.0).isActive = true

        self.backgroundImageView.addSubview(self.newAccountButton)
        self.newAccountButton.set(height: 44.0)
        self.newAccountButton.centerXAnchor.constraint(equalTo: self.backgroundImageView.centerXAnchor).isActive = true
        self.newAccountButton.bottomAnchor.constraint(equalTo: self.signinButton.topAnchor, constant: -20.0).isActive = true
    }

    @objc private func signinPressed(_: UIButton) {
        let controller = SignInController()
        self.navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func newAccountPressed(_: UIButton) {
        self.dismiss(animated: true) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appDelegate.createOrRestoreNewUser()
        }
    }
}
