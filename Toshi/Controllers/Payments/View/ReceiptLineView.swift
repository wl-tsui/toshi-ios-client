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

class ReceiptLineView: UIView {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .right
        view.adjustsFontForContentSizeCategory = true

        return titleLabel
    }()

    private lazy var amountLabel: UILabel = {
        let amountLabel = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.textColor = Theme.darkTextColor
        view.adjustsFontForContentSizeCategory = true

        return amountLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .red

        addSubview(titleLabel)
        addSubview(amountLabel)

        titleLabel.left(to: self)
        titleLabel.top(to: self)
        titleLabel.bottom(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ localized: String) {
        titleLabel.text = title
    }
}
