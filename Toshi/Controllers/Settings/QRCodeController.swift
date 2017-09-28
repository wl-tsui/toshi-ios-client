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

    static let addUsernameBasePath = "https://app.toshi.org/add/"
    static let addUserPath = "/add/"
    static let paymentWithUsernamePath = "/pay/"
    static let paymentWithAddressPath = "/ethereum:"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private lazy var qrCodeImageView: UIImageView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.medium(size: 20)
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.3

        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.regular(size: 17)
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.6
        view.numberOfLines = 2

        return view
    }()

    convenience init(for username: String, name: String) {
        self.init(nibName: nil, bundle: nil)

        title = Localized("profile_qr_code_title")

        qrCodeImageView.image = UIImage.imageQRCode(for: "\(QRCodeController.addUsernameBasePath)\(username)", resizeRate: 20.0)
        titleLabel.text = Localized("profile_qr_code_title")
        subtitleLabel.text = Localized("profile_qr_code_subtitle")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.settingsBackgroundColor
        view.addSubview(qrCodeImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        let top = navigationController?.navigationBar.frame.height ?? 0

        qrCodeImageView.height(300)
        qrCodeImageView.width(300)
        qrCodeImageView.centerX(to: view)
        qrCodeImageView.centerY(to: view, offset: -top)

        titleLabel.height(42)
        titleLabel.topToBottom(of: qrCodeImageView, offset: 10)
        titleLabel.left(to: view, offset: 27)
        titleLabel.right(to: view, offset: -27)

        subtitleLabel.height(48)
        subtitleLabel.topToBottom(of: titleLabel, offset: 10)
        subtitleLabel.left(to: view, offset: 27)
        subtitleLabel.right(to: view, offset: -27)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }
}

extension QRCodeController: UIToolbarDelegate {

    func position(for _: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
