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
import UIKit

protocol ToshiTableViewCellConfigurator: class {

    func configureCell(_ cell: ToshiTableViewCell, with cellData: TableCellData)
    func cellIdentifier(for components: TableCellDataComponents) -> String
}

class CellConfigurator: ToshiTableViewCellConfigurator { // lets say we have this configurator responsible for 

}

extension ToshiTableViewCellConfigurator {

    func configureCell(_ cell: ToshiTableViewCell, with cellData: TableCellData) {
        cell.titleLabel?.text = cellData.title
        cell.subtitleLabel?.text = cellData.subtitle
        cell.detailsLabel?.text = cellData.details
        cell.leftImageView?.image = cellData.leftImage
    }

    func cellIdentifier(for components: TableCellDataComponents) -> String {
        var reuseIdentifier = ToshiTitleCell.reuseIdentifier

        if components.contains(.titleSubtitleSwitchControlLeftImage) {
            reuseIdentifier = ToshiAvatarTitleSubtitleSwitchTableViewCell.reuseIdentifier
        } else if components.contains(.titleSubtitleDetailsLeftImage) || components.contains(.titleSubtitleLeftImage) {
            reuseIdentifier = ToshiAvatarTitleSubtitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitleSwitchControl) {
            reuseIdentifier = ToshiTitleSubtitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleSwitchControl) {
            reuseIdentifier = ToshiTitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleLeftImage) {
            reuseIdentifier = ToshiAvatarTitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitle) {
            reuseIdentifier = ToshiTitleSubtitleCell.reuseIdentifier
        }

        return reuseIdentifier
    }
}

class ToshiTableViewCell: UITableViewCell {

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

final class ToshiTitleCell: ToshiTableViewCell {

    override open func addSubviewsAndConstraints() {

    }
}

final class ToshiAvatarTitleCell: ToshiTableViewCell {

    open override func addSubviewsAndConstraints() {

    }
}

final class ToshiAvatarTitleSubtitleCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

    }
}

final class ToshiTitleSubtitleCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

    }
}

final class ToshiTitleSubtitleSwitchCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

    }
}

final class ToshiTitleSwitchCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

    }
}

final class ToshiAvatarTitleSubtitleSwitchTableViewCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

    }
}
