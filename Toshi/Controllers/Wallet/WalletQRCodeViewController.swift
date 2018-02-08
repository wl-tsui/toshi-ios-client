// Copyright (c) 2018 Token Browser, Inc
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

final class WalletQRCodeViewController: UIViewController {

    private lazy var qrCodeImageView = UIImageView()

    private lazy var closeButton: UIButton = {
        let button = UIButton()

        //TODO: get close icon and delete this stuff
        button.setTitle("X", for: .normal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.addBorder(ofColor: Theme.tintColor)
        button.layer.cornerRadius = 8

        button.accessibilityLabel = Localized("accessibility_close")
        button.addTarget(self,
                         action: #selector(closeButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Theme.preferredRegularMonospaced()
        label.textAlignment = .center

        return label
    }()

    // MARK: - Initialization

    init(address: String) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = Theme.viewBackgroundColor

        setupCloseButton()
        setupQRCodeImageView()
        setupAddressLabel(below: qrCodeImageView)

        addressLabel.text = address
        qrCodeImageView.image = UIImage.imageQRCode(for: address)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use the other initializer!")
    }

    // MARK: - View Setup

    private func setupCloseButton() {
        view.addSubview(closeButton)

        closeButton.top(to: layoutGuide(), offset: .mediumInterItemSpacing)
        closeButton.leadingToSuperview(offset: .mediumInterItemSpacing)
        closeButton.width(.defaultButtonHeight)
        closeButton.height(.defaultButtonHeight)
    }

    private func setupQRCodeImageView() {
        view.addSubview(qrCodeImageView)

        qrCodeImageView.centerXToSuperview()
        qrCodeImageView.centerYToSuperview()

        // Offset is * 2 so the same margin is applied to each side
        qrCodeImageView.widthToSuperview(offset: -(.largeInterItemSpacing * 2))

        NSLayoutConstraint.activate([
            qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor)
        ])
    }

    private func setupAddressLabel(below viewToPinToBottomOf: UIView) {
        view.addSubview(addressLabel)

        addressLabel.leadingToSuperview(offset: .largeInterItemSpacing)
        addressLabel.trailingToSuperview(offset: .largeInterItemSpacing)
        addressLabel.topToBottom(of: viewToPinToBottomOf, offset: .mediumInterItemSpacing)
    }

    // MARK: - Action Targets

    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }
}
