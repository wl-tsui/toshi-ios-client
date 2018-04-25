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

@objc public class ProfilesManager: NSObject {

    private(set) var profiles: [Profile] = []

    var yap: Yap {
        return Yap.sharedInstance
    }

    var profilesAvatarPaths: [String] {
        return profiles.compactMap { $0.avatar }
    }

    var profilesIds: [String] {
        return profiles.map { $0.toshiId }
    }

    private(set) lazy var databaseConnection: YapDatabaseConnection? = {
        let connection = yap.database?.newConnection()
        connection?.beginLongLivedReadTransaction()

        return connection
    }()

    public override init() {
        super.init()

        fetchContactsFromDatabase()
    }

    func profile(for toshiId: String) -> Profile? {
        return profiles.first(where: {  $0.toshiId == toshiId })
    }

    func updateProfile(_ profile: Profile) {
        guard let existingProfileIndex = profiles.index(where: { $0.toshiId == profile.toshiId }) else {
            profiles.append(profile)
            return
        }

        profiles[existingProfileIndex] = profile
    }

    public func clearProfiles() {
        profiles = []
    }

    func fetchContactsFromDatabase() {

        guard let contactsData = yap.retrieveObjects(in: ProfileKeys.storedContactKey) as? [Data] else {

            return
        }

        profiles.removeAll()

        for data in contactsData {

            if let serializedJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], var json = serializedJson {

                if json[ProfileKeys.toshiId] == nil {
                    json[ProfileKeys.toshiId] = json[ProfileKeys.address]
                    json[ProfileKeys.description] = json[ProfileKeys.about]
                }

                if let data = try? JSONSerialization.data(withJSONObject: json, options: []) {

                    let profile: Profile
                    do {
                        let jsonDecoder = JSONDecoder()
                        profile = try jsonDecoder.decode(Profile.self, from: data)
                    } catch let error {
                        assertionFailure("Can't decode json to Profile: \(error)")
                        continue
                    }

                    yap.insert(object: profile.data, for: profile.toshiId, in: ProfileKeys.storedContactKey)

                    guard profile.toshiId != Cereal.shared.address else { continue }
                    profiles.append(profile)
                }
            }
        }
    }
}

extension ProfilesManager: ContactsManagerProtocol {
    public func displayName(forPhoneIdentifier phoneNumber: String?) -> String {

        guard let profile = profiles.first(where: { $0.toshiId == phoneNumber }) else { return "" }
        return profile.nameOrDisplayName
    }

    public func signalAccounts() -> [SignalAccount] {
        return profiles.compactMap({ profile -> SignalAccount? in

            guard let signalRecipient = SignalRecipient(textSecureIdentifier: profile.toshiId) else { return nil }
            return SignalAccount(signalRecipient: signalRecipient)
        })
    }

    public func image(forPhoneIdentifier phoneNumber: String?) -> UIImage? {
        return nil
    }
}
