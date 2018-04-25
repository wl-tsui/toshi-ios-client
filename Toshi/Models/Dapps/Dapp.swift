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

/// An individual Dapp
struct Dapp: Codable {

    private let dappHostToAppend = "https://buy.coinbase.com"
    private let dappHostAppendingString = "?code=9a6fb1e3-af41-5677-9b67-8c8a0e365771&address="
    
    let name: String
    let dappId: Int
    let url: URL
    let avatarUrlString: String?
    let coverUrlString: String?
    let description: String?
    let categories: [Int]
    
    enum CodingKeys: String, CodingKey {
        case
        name,
        dappId = "dapp_id",
        url,
        avatarUrlString = "icon",
        coverUrlString = "cover",
        description,
        categories
    }

    var urlToLoad: URL {
        guard url.absoluteString == dappHostToAppend else { return url }

        let appendedUrlString = url.absoluteString.appending("\(dappHostAppendingString)\(Cereal.shared.paymentAddress)")
        guard let appendedUrl = URL(string: appendedUrlString) else { return url }

        return appendedUrl
    }
}

extension Dapp: BrowseableItem {

    var nameForBrowseAndSearch: String {
        return name
    }
    
    var descriptionForSearch: String? {
        return description
    }
    
    var avatarPath: String {
        return String.contentsOrEmpty(for: avatarUrlString)
    }
    
    var shouldShowRating: Bool {
        return false
    }
    
    var rating: Float? {
        return nil
    }
}

typealias DappInfo = (dappURL: URL, imagePath: String?, headerText: String?)

/// Convenience class for decoding an array of Dapps with the key "results"
final class DappResults: Codable {
    
    let dapps: [Dapp]
    
    enum CodingKeys: String, CodingKey {
        case
        dapps
    }
}
