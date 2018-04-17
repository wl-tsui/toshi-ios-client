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

protocol SystemSharing {

    /// Shares a single item with the system share sheet
    ///
    /// - Parameter item: The item to share.
    func shareWithSystemSheet(item: Any)

    /// Shares an array of items with the system share sheet.
    ///
    /// - Parameter items: The items to share
    func shareWithSystemSheet(items: [Any])
}

// MARK: - Default Implementation

extension SystemSharing {

    func shareWithSystemSheet(items: [Any]) {
        let shareSheet = UIActivityViewController(activityItems: items, applicationActivities: [])

        Navigator.presentModally(shareSheet)
    }

    func shareWithSystemSheet(item: Any) {
        shareWithSystemSheet(items: [item])
    }
}
