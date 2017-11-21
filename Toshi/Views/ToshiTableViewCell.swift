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

    func configureCell(_ cell: BasicTableViewCell, with cellData: TableCellData)
    func cellIdentifier(for components: TableCellDataComponents) -> String
}

class CellConfigurator: ToshiTableViewCellConfigurator { // lets say we have this configurator responsible for 

}

extension ToshiTableViewCellConfigurator {

    func configureCell(_ cell: BasicTableViewCell, with cellData: TableCellData) {
        cell.titleLabel?.text = cellData.title
        cell.subtitleLabel?.text = cellData.subtitle
        cell.detailsLabel?.text = cellData.details
        cell.leftImageView?.image = cellData.leftImage
    }

    func cellIdentifier(for components: TableCellDataComponents) -> String {
        var reuseIdentifier = TitleCell.reuseIdentifier

        if components.contains(.titleSubtitleSwitchControlLeftImage) {
            reuseIdentifier = AvatarTitleSubtitleSwitchTableViewCell.reuseIdentifier
        } else if components.contains(.titleSubtitleDetailsLeftImage) || components.contains(.titleSubtitleLeftImage) {
            reuseIdentifier = AvatarTitleSubtitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitleSwitchControl) {
            reuseIdentifier = TitleSubtitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleSwitchControl) {
            reuseIdentifier = TitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleLeftImage) {
            reuseIdentifier = AvatarTitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitle) {
            reuseIdentifier = TitleSubtitleCell.reuseIdentifier
        }

        return reuseIdentifier
    }
}
