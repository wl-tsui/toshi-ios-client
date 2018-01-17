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

class ReceiptView: UIView {

    private lazy var amountLine: ReceiptLineView = {
        let amountLine = ReceiptLineView()
        amountLine.setTitle(Localized("confirmation_amount"))

        return amountLine
    }()

    private lazy var estimatedNetworkFeesLine: ReceiptLineView = {
        let estimatedNetworkFeesLine = ReceiptLineView()
        estimatedNetworkFeesLine.setTitle(Localized("confirmation_estimated_network_fees"))

        return estimatedNetworkFeesLine
    }()

    private lazy var totalLine: ReceiptLineView = {
        let totalLine = ReceiptLineView()
        totalLine.setTitle(Localized("confirmation_total"))

        return totalLine
    }()

    private lazy var ethereumAmountLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.textColor = Theme.lightGreyTextColor
        view.textAlignment = .right
        view.adjustsFontForContentSizeCategory = true

        view.text = "Just testing 193819283 ETH"

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .red

        let stackView = UIStackView()
        stackView.addBackground(with: Theme.viewBackgroundColor)
        stackView.axis = .vertical
        stackView.alignment = .center

        addSubview(stackView)
        stackView.leftToSuperview()
        stackView.rightToSuperview()
        stackView.top(to: self)

        stackView.addWithDefaultConstraints(view: amountLine)
        stackView.addSpacing(.mediumInterItemSpacing, after: amountLine)
        stackView.addWithDefaultConstraints(view: estimatedNetworkFeesLine)

        let separator = UIView()
        separator.backgroundColor = Theme.borderColor
        separator.height(.lineHeight)

        stackView.addSpacing(.largeInterItemSpacing, after: estimatedNetworkFeesLine)
        stackView.addWithDefaultConstraints(view: separator)
        stackView.addSpacing(.largeInterItemSpacing, after: separator)
        stackView.addWithDefaultConstraints(view: totalLine)
        stackView.addWithDefaultConstraints(view: ethereumAmountLabel)
        stackView.addSpacing(.mediumInterItemSpacing, after: ethereumAmountLabel)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
