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
import SweetSwift
import KeychainSwift

enum ProfileKeys {
    static let name = "name"
    static let username = "username"
    static let address = "token_id"
    static let toshiId = "toshi_id"
    static let paymentAddress = "payment_address"
    static let location = "location"
    static let description = "description"
    static let about = "about"
    static let avatar = "avatar"
    static let isApp = "is_app"
    static let verified = "verified"
    static let isPublic = "public"
    static let reputationScore = "reputation_score"
    static let averageRating = "average_rating"
    static let localCurrency = "local_currency"
    static let type = "type"

    static let viewExtensionName = "TokenContactsDatabaseViewExtensionName"
    static let favoritesCollectionKey = "TokenContacts"
    static let legacyStoredUserKey = "StoredUser"
    static let currentLocalUserAddressKey = "currentLocalUserAddress"
    static let storedContactKey = "storedContactKey"
    static let localUserSettingsKey = "localUserSettings"
}
