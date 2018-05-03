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

typealias ProfileInfo = (address: String, paymentAddress: String?, avatarPath: String?, name: String?, username: String?, isLocal: Bool)

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

    private static let userTypeString = "user"
    private static let botTypeString = "bot"
    private static let groupTypeString = "groupbot"

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
            return ProfileType.userTypeString
        case .bot:
            return ProfileType.botTypeString
        case .group:
            return ProfileType.groupTypeString
        }
    }

    static func typeFromTypeString(_ typeString: String?) -> ProfileType {
        guard let validType = typeString else { return .user }

        switch validType {
        case botTypeString:
            return .bot
        case groupTypeString:
            return .group
        default:
            return .user
        }
    }
}

/// An individual Profile
struct Profile: Codable {

    let type: String?
    let name: String?
    let username: String
    let toshiId: String
    var avatar: String?
    let description: String?
    let paymentAddress: String?
    let location: String?
    var isPublic: Bool?
    let reputationScore: Float?
    let averageRating: Float?
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
        reviewCount = "review_count"
    }

    var localCurrency: String {
        return userSettings[ProfileKeys.localCurrency] as? String ?? Profile.defaultCurrency
    }

    var hashValue: Int {
        return toshiId.hashValue
    }

    var displayUsername: String {
        return "@\(username)"
    }

    var nameOrDisplayName: String {
        let nameOrEmpty = String.contentsOrEmpty(for: name)
        guard !nameOrEmpty.isEmpty else {

            return displayUsername
        }

        return nameOrEmpty
    }

    var nameOrUsername: String {
        return name ?? username
    }

    var profileType: ProfileType {
        return ProfileType.typeFromTypeString(type)
    }

    var balance = NSDecimalNumber.zero

    private var userSettings: [String: Any] = [:]
    private(set) var cachedCurrencyLocale: Locale = .current

    var verified: Bool {
        return userSettings[ProfileKeys.verified] as? Bool ?? false
    }

    var isBot: Bool {
        return type != ProfileType.user.typeString
    }

    private static var _current: Profile?
    static var current: Profile? {
        get {
            if _current == nil {
                guard let profile = Profile.retrieveCurrentUserFromStore() else { return nil }
                _current = profile
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

    var userInfo: ProfileInfo {
        return ProfileInfo(address: toshiId, paymentAddress: paymentAddress, avatarPath: avatar, name: nameOrDisplayName, username: displayUsername, isLocal: true)
    }

    var data: Data? {
        return try? JSONEncoder().encode(self)
    }

    static var defaultCurrency: String {
        return Locale.current.currencyCode ?? "USD"
    }

    var isBlocked: Bool {
        let blockingManager = OWSBlockingManager.shared()

        return blockingManager.blockedPhoneNumbers().contains(toshiId)
    }

    var isCurrentUser: Bool {
        return toshiId == Cereal.shared.address
    }

    static func retrieveCurrentUserFromStore() -> Profile? {
        guard _current == nil else { return _current }

        var profile: Profile?

        // migrate old user storage
        if let userData = (Yap.sharedInstance.retrieveObject(for: ProfileKeys.legacyStoredUserKey) as? Data) {
            Yap.sharedInstance.insert(object: userData, for: Cereal.shared.address, in: ProfileKeys.storedContactKey)
            Yap.sharedInstance.removeObject(for: ProfileKeys.legacyStoredUserKey)
        }

        guard var userData = (Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: ProfileKeys.storedContactKey) as? Data),
            let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
            var json = deserialised as? [String: Any] else { return profile }

        var userSettings = Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: ProfileKeys.localUserSettingsKey) as? [String: Any] ?? [:]

        // Migration from old model with changes to some variables
        var shouldSaveAfterMigration = false

        // Because of payment address migration, we have to override the stored payment address.
        // Otherwise users will be sending payments to the wrong address.
        if json[ProfileKeys.paymentAddress] as? String != Cereal.shared.paymentAddress {
            json[ProfileKeys.paymentAddress] = Cereal.shared.paymentAddress

            if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                userData = updatedData
                shouldSaveAfterMigration = true
            }
        }

        if json[ProfileKeys.toshiId] == nil {
            json[ProfileKeys.toshiId] = json[ProfileKeys.address]
            json[ProfileKeys.type] = ProfileType.user.typeString
            json[ProfileKeys.description] = json[ProfileKeys.about]

            if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                userData = updatedData
                shouldSaveAfterMigration = true
            }
        }

        if shouldSaveAfterMigration {
            Yap.sharedInstance.insert(object: userData, for: Cereal.shared.address, in: ProfileKeys.storedContactKey)
        }

        do {
            let jsonDecoder = JSONDecoder()
            profile = try jsonDecoder.decode(Profile.self, from: userData)
        } catch let error {
            print(error)
            assertionFailure("Can't decode retrieved current user data")
        }

        // migrations
        var shouldSaveMigration = false
        if userSettings[ProfileKeys.verified] == nil {
            if json[ProfileKeys.verified] != nil {
                userSettings[ProfileKeys.verified] = json[ProfileKeys.verified]
            } else {
                userSettings[ProfileKeys.verified] = 0
            }
            shouldSaveMigration = true
        }

        if userSettings[ProfileKeys.localCurrency] == nil {
            userSettings[ProfileKeys.localCurrency] = Profile.defaultCurrency
            shouldSaveMigration = true
        }

        profile?.userSettings = userSettings
        if shouldSaveMigration {
            profile?.saveSettings()
        }

        profile?.updateLocalCurrencyLocaleCache()

        return profile
    }

    mutating func updatePublicState(to isPublic: Bool) {
        self.isPublic = isPublic

        guard let validDictionary = dictionary else { return }
        IDAPIClient.shared.updateUser(validDictionary) { _, _ in }

        save()
    }

    static func name(from username: String) -> String {
        guard username.hasPrefix("@") else {
            // Does not need to be cleaned up
            return username
        }

        let index = username.index(username.startIndex, offsetBy: 1)
        return String(username[index...])
    }

    static func retrieveCurrentUser() {
        guard let user = Profile.retrieveCurrentUserFromStore() else { return }
        current = user

        NotificationCenter.default.post(name: .userCreated, object: nil)
    }

    static func setupCurrentProfile(_ profile: Profile) {
        current = profile

        Yap.sharedInstance.setupForNewUser(with: profile.toshiId)

        let newUserSettings: [String: Any] = [
            ProfileKeys.localCurrency: Profile.defaultCurrency,
            ProfileKeys.verified: 0
        ]

        current?.userSettings = Yap.sharedInstance.retrieveObject(for: Cereal.shared.address, in: ProfileKeys.localUserSettingsKey) as? [String: Any] ?? newUserSettings
        current?.saveSettings()
        current?.updateLocalCurrencyLocaleCache()

        NotificationCenter.default.post(name: .userCreated, object: nil)
    }

    mutating func updateLocalCurrency(code: String? = nil, shouldSave: Bool = true) {
        if let localCurrency = code {
            userSettings[ProfileKeys.localCurrency] = localCurrency

            updateLocalCurrencyLocaleCache()

            if shouldSave {
                saveSettings()
            }
        }
    }

    mutating func updateAvatarPath(_ avatarPath: String) {
        avatar = avatarPath
        save()
    }

    mutating func updateVerificationState(_ verified: Bool) {
        userSettings[ProfileKeys.verified] = verified
        saveSettings()
    }

    private func saveSettings() {
        Yap.sharedInstance.insert(object: userSettings, for: toshiId, in: ProfileKeys.localUserSettingsKey)
    }

    private mutating func updateLocalCurrencyLocaleCache() {
        if Locale.current.currencyCode == self.localCurrency {
            cachedCurrencyLocale = Locale.current
        } else if let defaultLocaleForCurrency = Currency.defaultLocalesForCurrencies[localCurrency] {
            self.cachedCurrencyLocale = Locale(identifier: defaultLocaleForCurrency)
        } else {
            self.cachedCurrencyLocale = Locale.current
        }
    }

    private func save() {
        guard let encodedData = try? JSONEncoder().encode(self) else { return }
        Yap.sharedInstance.insert(object: encodedData, for: toshiId, in: ProfileKeys.storedContactKey)
    }
}

extension Profile: Hashable {

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.toshiId == rhs.toshiId
    }
}
