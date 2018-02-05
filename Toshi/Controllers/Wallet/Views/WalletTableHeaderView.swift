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
    func walletHeaderViewDidRequireCopyAddress(_ headrView: WalletTableHeaderView, address: String)
    func walletHeaderViewDidRequireOpenAddress(_ headrView: WalletTableHeaderView, address: String)
}

final class WalletTableHeaderView: UIView {

    private let contentViewInset: CGFloat = 15
    private let qrCodeImageSize: CGFloat = 40
    private let interItemInset: CGFloat = 20

    var walletAddress = "" {
        didSet {
            setupAddressText()
            setupQRCodeImage()
        }
    }

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.backgroundColor = Theme.greyTextColor
        imageView.size(CGSize(width: self.qrCodeImageSize, height: self.qrCodeImageSize))

        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.greyTextColor
        label.text = Localized("wallet_address_title")
        label.font = Theme.preferredRegularSmall()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var walletAddressLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.preferredRegular()
        label.text = "0xf1c..75fr8"
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private lazy var contentView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.cornerRadius = 10.0
        view.backgroundColor = Theme.viewBackgroundColor
        view.height(80).priority = .required

        return view
    }()

    private func setupQRCodeImage() {

    }

    private func setupAddressText() {
        walletAddressLabel.text = walletAddress
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        addSubview(contentView)
        let contentInsets = UIEdgeInsets(top: contentViewInset, left: contentViewInset, bottom: -contentViewInset, right: -contentViewInset)
        contentView.edges(to: self, insets: contentInsets, priority: .required, isActive: true)

        contentView.addSubview(qrCodeImageView)
        qrCodeImageView.left(to: contentView, offset: interItemInset, priority: .required, isActive: true)
        qrCodeImageView.centerY(to: contentView)

        contentView.addSubview(titleLabel)
        titleLabel.top(to: qrCodeImageView)
        titleLabel.leftToRight(of: qrCodeImageView, offset: interItemInset)

        contentView.addSubview(walletAddressLabel)
        walletAddressLabel.bottom(to: qrCodeImageView)
        walletAddressLabel.left(to: titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
