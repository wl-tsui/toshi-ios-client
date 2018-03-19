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

/// An individual Dapp category section
final class DappCategory: Codable {

    let categoryId: Int
    let type: String?
    let dapps: [Dapp]

    enum CodingKeys: String, CodingKey {
        case
        categoryId = "category_id",
        type,
        dapps
    }
}

typealias DappCategoryInfo = [Int: String]

/// Convenience class for decoding an array of DappCategories with the key "sections"
final class DappCategoryResults: Codable {

    let categories: [DappCategory]
    let categoriesInfo: DappCategoryInfo

    enum CodingKeys: String, CodingKey {
        case
        categories = "sections",
        categoriesInfo = "categories"
    }
}
