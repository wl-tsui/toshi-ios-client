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
import TinyConstraints

protocol WalletTableViewHeaderDelegate: class {
    func copyAddress(_ address: String, from headerView: WalletTableHeaderView)
    func openAddress(_ address: String, from headerView: WalletTableHeaderView)
}

// MARK: - View

final class WalletTableHeaderView: UIView {

    private let walletAddress: String
    private weak var delegate: WalletTableViewHeaderDelegate?

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        let qrCodeImageSize: CGFloat = 40

        imageView.width(qrCodeImageSize)
        imageView.height(qrCodeImageSize)

        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.greyTextColor
        label.text = Localized("wallet_address_title")
        label.font = Theme.preferredFootnote()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var walletAddressLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredSemibold()
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .custom)

        button.layer.borderColor = Theme.tintColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        button.contentEdgeInsets = UIEdgeInsets(top: .smallInterItemSpacing, left: .mediumInterItemSpacing, bottom: .smallInterItemSpacing, right: .mediumInterItemSpacing)
        button.titleLabel?.font = Theme.preferredFootnote()
        button.setTitle(Localized("copy_action_title"), for: .normal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.addTarget(self, action: #selector(copyAddressTapped), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }()

    // MARK: - Initialization

    /// Designated initializer
    ///
    /// - Parameters:
    ///   - frame: The frame to pass through to super.
    ///   - address: The address to display
    ///   - delegate: The delegate to notify of changes.
    init(frame: CGRect, address: String, delegate: WalletTableViewHeaderDelegate) {
        walletAddress = address
        self.delegate = delegate
        super.init(frame: frame)

        setupBackground()
        setupContentView()

        walletAddressLabel.text = walletAddress
        qrCodeImageView.image = UIImage.imageQRCode(for: walletAddress)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupBackground() {
        let topBackground = UIView()
        topBackground.backgroundColor = Theme.tintColor

        let bottomBackground = UIView()
        bottomBackground.backgroundColor = Theme.lightGrayBackgroundColor

        addSubview(topBackground)
        addSubview(bottomBackground)

        topBackground.edgesToSuperview(excluding: .bottom)
        bottomBackground.edgesToSuperview(excluding: .top)
        bottomBackground.topToBottom(of: topBackground)
        bottomBackground.height(to: topBackground)
    }

    private func setupContentView() {
        let contentView = UIView(withAutoLayout: true)
        contentView.layer.cornerRadius = 10.0

        contentView.addShadow(xOffset: 0, yOffset: 2, radius: 4)
        contentView.backgroundColor = Theme.viewBackgroundColor

        addSubview(contentView)

        let spacing = CGFloat.spacingx3
        contentView.topToSuperview(offset: spacing)
        contentView.bottomToSuperview(offset: -spacing)
        contentView.leftToSuperview(offset: spacing)
        contentView.rightToSuperview(offset: spacing)

        let outerStackView = UIStackView()
        outerStackView.axis = .horizontal
        outerStackView.alignment = .center
        outerStackView.spacing = .spacingx3

        contentView.addSubview(outerStackView)
        outerStackView.centerYToSuperview()
        outerStackView.leftToSuperview(offset: .largeInterItemSpacing)
        outerStackView.rightToSuperview(offset: .largeInterItemSpacing)

        outerStackView.addArrangedSubview(qrCodeImageView)
        addAddress(to: outerStackView)
        outerStackView.addArrangedSubview(copyButton)
    }

    private func addAddress(to stackView: UIStackView) {
        let innerStackView = UIStackView()
        innerStackView.axis = .vertical
        innerStackView.alignment = .center

        stackView.addArrangedSubview(innerStackView)

        innerStackView.addWithDefaultConstraints(view: titleLabel)
        innerStackView.addWithDefaultConstraints(view: walletAddressLabel)
    }

    // MARK: - Action Targets

    @objc private func copyAddressTapped() {
        delegate?.copyAddress(walletAddress, from: self)
    }

    @objc private func openAddressTapped() {
        delegate?.openAddress(walletAddress, from: self)
    }

}
