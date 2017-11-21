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

class BasicTableViewCell: UITableViewCell {

    private(set) var titleLabel: UILabel?
    private(set) var subtitleLabel: UILabel?
    private(set) var detailsLabel: UILabel?
    private(set) var leftImageView: UIImageView?
    private(set) var switchControl: UISwitch?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubviewsAndConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func addSubviewsAndConstraints() {
        fatalError("addSubviewsAndConstraints() Should be overriden")
    }
}