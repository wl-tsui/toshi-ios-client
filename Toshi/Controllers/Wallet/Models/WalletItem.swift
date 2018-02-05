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

import Foundation

protocol WalletItem {
    var title: String { get }
    var subtitle: String? { get }
    var imagePath: String? { get }
}

final class WalletItemObject {

    // temporary placeholder for wallet item

    var itemTitle = ""
    var itemSubtitle = ""
    var itemImagePath = ""

    init(title: String, subtitle: String, imagePath: String) {
        self.itemTitle = title
        self.itemSubtitle = subtitle
        self.itemImagePath = imagePath
    }
}

extension WalletItemObject: WalletItem {

    var title: String {
        return itemTitle
    }

    var subtitle: String? {
        return itemSubtitle
    }

    var imagePath: String? {
        return itemImagePath
    }
}
