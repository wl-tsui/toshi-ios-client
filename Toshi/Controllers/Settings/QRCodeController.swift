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

class QRCodeController: DisappearingNavBarViewController {

    static let addUsernameBasePath = "https://app.toshi.org/add/"
    static let addUserPath = "/add/"
    static let paymentWithUsernamePath = "/pay/"
    static let paymentWithAddressPath = "ethereum:"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private lazy var qrCodeImageView: UIImageView = UIImageView()
    private lazy var qrCodeImageView2: UIImageView = UIImageView()
    private lazy var qrCodeImageView3: UIImageView = UIImageView()

    private lazy var subtitleLabel = TextLabel(Localized("profile_qr_code_subtitle"))

    convenience init(for username: String, name: String) {
        self.init(nibName: nil, bundle: nil)

        navBar.setTitle(Localized("profile_qr_code_title"))

        let qrCodeImage = UIImage.imageQRCode(for: "\(QRCodeController.addUsernameBasePath)\(username)", resizeRate: 20.0)
        qrCodeImageView.image = qrCodeImage
        qrCodeImageView2.image = qrCodeImage
        qrCodeImageView3.image = qrCodeImage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.lightGrayBackgroundColor
    }

    /// The view to use as the trigger to show or hide the background.
    override var backgroundTriggerView: UIView {
        return subtitleLabel
    }

    override var titleTriggerView: UIView {
        return qrCodeImageView
    }

    override func addScrollableContent(to contentView: UIView) {
        let spacer = addTopSpacer(to: contentView)
        spacer.backgroundColor = Theme.lightGrayBackgroundColor

        contentView.showDebugBorder(color: .red)

        contentView.addSubview(subtitleLabel)
        contentView.addSubview(qrCodeImageView)
        contentView.addSubview(qrCodeImageView2)
        contentView.addSubview(qrCodeImageView3)

        subtitleLabel.topToBottom(of: spacer)
        subtitleLabel.leftToSuperview(offset: .largeInterItemSpacing)
        subtitleLabel.rightToSuperview(offset: .largeInterItemSpacing)

        qrCodeImageView.topToBottom(of: subtitleLabel, offset: .giantInterItemSpacing, relation: .equalOrGreater)
        qrCodeImageView.height(300)
        qrCodeImageView.width(300)
        qrCodeImageView.centerXToSuperview()

        qrCodeImageView2.topToBottom(of: qrCodeImageView, offset: .largeInterItemSpacing)
        qrCodeImageView2.height(300)
        qrCodeImageView2.width(300)
        qrCodeImageView2.centerXToSuperview()

        qrCodeImageView3.topToBottom(of: qrCodeImageView2, offset: .largeInterItemSpacing)
        qrCodeImageView3.height(300)
        qrCodeImageView3.width(300)
        qrCodeImageView3.centerXToSuperview()
        qrCodeImageView3.bottomToSuperview(offset: -.largeInterItemSpacing)
    }
}

extension QRCodeController: UIToolbarDelegate {

    func position(for _: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
