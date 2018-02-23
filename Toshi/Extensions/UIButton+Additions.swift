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

extension UIButton {

    static func borderedButton(with tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .custom)

        button.layer.borderColor = tintColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: .smallInterItemSpacing, left: .mediumInterItemSpacing, bottom: .smallInterItemSpacing, right: .mediumInterItemSpacing)
        button.titleLabel?.font = Theme.preferredProTextSemibold(range: 15...17)
        button.setTitleColor(tintColor, for: .normal)
        button.imageView?.contentMode = .center

        return button
    }
}
