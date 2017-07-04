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

class PaymentConfirmationController: AlertController {

    static let contentWidth: CGFloat = 310

    fileprivate var userInfo: UserInfo
    fileprivate var value = NSDecimalNumber.zero

    fileprivate var review: String = ""

    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel("Rate \(String(describing: self.userInfo.username))")

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = TextLabel("How would you rate your experience with this app?")
        view.textAlignment = .center
        view.textColor = Theme.darkTextColor

        return view
    }()

    init(userInfo: UserInfo, value: NSDecimalNumber) {
        self.userInfo = userInfo

        super.init(nibName: nil, bundle: nil)

        self.value = value

        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func cancel(_: ActionButton) {
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCustomContentView()
    }

    fileprivate func setupCustomContentView() {
        if let customView = Bundle.main.loadNibNamed("PaymentRequestInfoView", owner: nil, options: nil)?.first as? PaymentRequestInfoView {
            customView.set(height: customView.frame.height)
            customView.translatesAutoresizingMaskIntoConstraints = false
            customView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

            if let path = self.userInfo.avatarPath as String? {
                AvatarManager.shared.avatar(for: path) { image, _ in
                    customView.userAvatarImageView.image = image
                }
            }

            customView.userDisplayNameLabel.text = self.userInfo.name
            customView.userNameLabel.text = self.userInfo.username
            customView.valueLabel.attributedText = EthereumConverter.balanceSparseAttributedString(forWei: self.value, exchangeRate: EthereumAPIClient.shared.exchangeRate, width: customView.valueLabel.frame.width)

            customView.mode = (self.userInfo.isLocal == true) ? Mode.localUser : Mode.remoteUser

            self.customContentView = customView

            RatingsClient.shared.scores(for: self.userInfo.address) { score in
                if let view = self.customContentView as? PaymentRequestInfoView {
                    view.ratingView.set(rating: Float(score.score), animated: true)
                    view.ratingCountLabel.text = "(\(score.count))"
                }
            }
        }
    }
}
