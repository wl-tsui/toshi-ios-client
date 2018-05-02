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

final class WalletEmptyView: UIView {

    var title: String? = "" {
        didSet {
            updateText()
        }
    }

    var details: String? = "" {
        didSet {
            updateText()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = Theme.viewBackgroundColor
        addSubviewsAndConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.darkTextColor
        label.font = Theme.preferredSemibold()
        label.textAlignment = .center

        return label
    }()

    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.greyTextColor
        label.font = Theme.preferredProTextRegular()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.height(CGFloat.mediumInterItemSpacing, relation: .equalOrGreater)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return label
    }()

    private lazy var stackView = UIStackView()

    // MARK: - Update UI

    private func addSubviewsAndConstraints() {
        stackView.axis = .vertical
        stackView.alignment = .center

        addSubview(stackView)

        stackView.centerY(to: self)
        stackView.leftToSuperview()
        stackView.rightToSuperview()

        stackView.addArrangedSubview(titleLabel)
        stackView.addSpacing(CGFloat.mediumInterItemSpacing, after: titleLabel)
        stackView.addArrangedSubview(detailsLabel)
    }

    private func updateText() {
        titleLabel.text = title
        detailsLabel.text = details
    }
}
