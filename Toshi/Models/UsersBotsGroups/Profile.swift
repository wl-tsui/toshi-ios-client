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

/// Users, bots and groups front page
struct ProfilesFrontPage: Codable {

    let sections: [ProfilesFrontPageSection]

    enum CodingKeys: String, CodingKey {
        case
        sections
    }
}

struct ProfilesFrontPageSection: Codable {

    let name: String
    let query: String
    let profiles: [Profile]

    enum CodingKeys: String, CodingKey {
        case
        name,
        query,
        profiles = "results"
    }
}

enum ProfileType: Int {
    case user
    case bot
    case group

    var title: String {
        switch self {
        case .user:
            return Localized.users_section_title
        case .bot:
            return Localized.bots_section_title
        case .group:
            return Localized.groups_section_title
        }
    }

    var typeString: String {
        switch self {
        case .user:
            return "user"
        case .bot:
            return "bot"
        case .group:
            return "groupbot"
        }
    }
}

/// An individual Profile
struct Profile: Codable {

    let type: String
    let name: String?
    let username: String
    let toshiId: String
    let avatar: String?
    let description: String?
    let paymentAddress: String?
    let location: String?
    var isPublic: Bool?
    let reputationScore: Float?
    let averageRating: Float?
    let localCurrency: String?
    let reviewCount: Int?

    enum CodingKeys: String, CodingKey {
        case
        type,
        name,
        username,
        toshiId = "toshi_id",
        avatar,
        description,
        paymentAddress = "payment_address",
        location,
        isPublic = "public",
        reputationScore = "reputation_score",
        averageRating = "average_rating",
        localCurrency = "local_currency",
        reviewCount = "review_count"
    }

    var displayUsername: String {
        return "@\(username)"
    }

    var nameOrDisplayName: String {
        guard !(name ?? "").isEmpty else {

            return displayUsername
        }

        return name ?? ""
    }

    private var userSettings: [String: Any] = [:]
    private var cachedCurrencyLocale: Locale = .current

    var verified: Bool {
        return userSettings[TokenUser.Constants.verified] as? Bool ?? false
    }

    private static var _current: Profile?
    private(set) static var current: Profile? {
        get {
            if _current == nil {
                guard let user = TokenUser.retrieveCurrentUserFromStore() else { return nil }
                let jsonDecoder = JSONDecoder()
                guard let decodedProfile = try? jsonDecoder.decode(Profile.self, from: user.json) else { return nil }
                _current = decodedProfile
            }

            return _current
        }
        set {

            if let user = newValue {
                user.save()
            }

            _current = newValue
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .currentUserUpdated, object: nil)
            }
        }
    }

    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }

    mutating func updatePublicState(to isPublic: Bool) {
        self.isPublic = isPublic

        guard let validDictionary = dictionary else { return }
        IDAPIClient.shared.updateUser(validDictionary) { _, _ in }

        save()
    }

    static func retrieveCurrentUser() {
        guard let user = TokenUser.retrieveCurrentUserFromStore() else { return }
        let jsonDecoder = JSONDecoder()
        guard let decodedProfile = try? jsonDecoder.decode(Profile.self, from: user.json) else { return }
        current = decodedProfile

        NotificationCenter.default.post(name: .userCreated, object: nil)
    }

    mutating func updateLocalCurrency(code: String? = nil, shouldSave: Bool = true) {
        if let localCurrency = code {
            userSettings[TokenUser.Constants.localCurrency] = localCurrency

            adjustToLocalCurrency()

            if shouldSave {
                saveSettings()
            }
        }
    }

    mutating func updateVerificationState(_ verified: Bool) {
        userSettings[TokenUser.Constants.verified] = verified
        saveSettings()
    }

    private func saveSettings() {
        Yap.sharedInstance.insert(object: userSettings, for: toshiId, in: TokenUser.localUserSettingsKey)
    }

    private mutating func adjustToLocalCurrency() {
        updateLocalCurrencyLocaleCache()

        ExchangeRateClient.updateRateAndNotify()
    }

    private mutating func updateLocalCurrencyLocaleCache() {
        if Locale.current.currencyCode == self.localCurrency {
            cachedCurrencyLocale = Locale.current
        } else if let currency = localCurrency, let defaultLocaleForCurrency = Currency.defaultLocalesForCurrencies[currency] {
            self.cachedCurrencyLocale = Locale(identifier: defaultLocaleForCurrency)
        } else {
            self.cachedCurrencyLocale = Locale.current
        }
    }

    private func save() {
        guard let encodedData = try? JSONEncoder().encode(self) else { return }
        Yap.sharedInstance.insert(object: encodedData, for: toshiId, in: TokenUser.storedContactKey)
    }
}
