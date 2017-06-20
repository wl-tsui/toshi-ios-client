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
import TinyConstraints

class AddMoneyHeader: UIView {

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.medium(size: 20)
        view.textColor = Theme.darkTextColor
        view.numberOfLines = 0

        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.regular(size: 17)
        view.textColor = Theme.darkTextColor
        view.numberOfLines = 0

        return view
    }()

    convenience init(title: String, subtitle: String) {
        self.init()

        self.titleLabel.text = title
        addSubview(self.titleLabel)

        self.subtitleLabel.text = subtitle
        addSubview(self.subtitleLabel)

        self.titleLabel.top(to: self, offset: 15)
        self.titleLabel.left(to: self, offset: 15)
        self.titleLabel.right(to: self, offset: -15)

        self.subtitleLabel.topToBottom(of: self.titleLabel, offset: 5)
        self.subtitleLabel.left(to: self, offset: 15)
        self.subtitleLabel.right(to: self, offset: -15)
        self.subtitleLabel.bottom(to: self)
    }
}
