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

final class CollectibleCellConfigurator: CellConfigurator {

    private var collectible: CollectibleToken

    init(collectible: CollectibleToken) {
        self.collectible = collectible
    }

    func configureCell(_ cell: CollectibleCell, dataSourceName: String) {
        cell.titleTextField.text = collectible.name ?? "\(dataSourceName) #\(collectible.displayId)"
        cell.leftImageView.image = ImageAsset.collectible_placeholder

        if let leftImagePath = collectible.image {
            AvatarManager.shared.avatar(for: leftImagePath, completion: { image, path in
                if leftImagePath == path {
                    cell.leftImageView.image = image
                }
            })
        }

        cell.subtitleLabel.text = collectible.description

        cell.titleTextField.setDynamicFontBlock = { [weak cell] in
            guard let strongCell = cell else { return }
            strongCell.titleTextField.font = Theme.preferredSemibold()
        }
    }
}
