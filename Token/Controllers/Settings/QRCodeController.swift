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
import SweetUIKit
import CoreImage

class QRCodeController: UIViewController {

    static let addUsernameBasePath = "https://app.tokenbrowser.com/add/"

    static let addUserPath = "/add/"
    static let paymentWithUsernamePath = "/pay/"
    static let paymentWithAddressPath = "/ethereum:"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private lazy var qrCodeImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.set(height: 300)
        view.set(width: 300)

        return view
    }()

    private lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.light(size: 35)
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.3

        return view
    }()

    private lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.6

        return view
    }()

    convenience init(for username: String, name: String) {
        self.init(nibName: nil, bundle: nil)

        self.title = "My QR Code"

        self.qrCodeImageView.image = UIImage.imageQRCode(for: "\(QRCodeController.addUsernameBasePath)\(username)", resizeRate: 20.0)
        self.usernameLabel.text = username
        self.nameLabel.text = name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.settingsBackgroundColor
        self.view.addSubview(self.qrCodeImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.usernameLabel)

        let top: CGFloat = self.navigationController?.navigationBar.frame.height ?? 0.0

        self.qrCodeImageView.set(height: 300)
        self.qrCodeImageView.set(width: 300)
        self.qrCodeImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.qrCodeImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -top).isActive = true

        self.nameLabel.set(height: 42)
        self.nameLabel.topAnchor.constraint(equalTo: self.qrCodeImageView.bottomAnchor, constant: 16).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true

        self.usernameLabel.set(height: 24)
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: 6).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true
    }
}

extension QRCodeController: UIToolbarDelegate {

    func position(for _: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
