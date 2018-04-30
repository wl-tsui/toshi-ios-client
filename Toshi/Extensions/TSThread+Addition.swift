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

extension TSThread {

    /// Needs to be called on main thread as it involves UIAppDelegate
    func recipient() -> Profile? {
        guard let recipientAddress = contactIdentifier() else { return nil }

        var recipient: Profile?

        let retrievedData = contactData(for: recipientAddress)

        if let userData = retrievedData {

            do {
                let jsonDecoder = JSONDecoder()
                recipient = try jsonDecoder.decode(Profile.self, from: userData)
            } catch { }
        } else {
            recipient = SessionManager.shared.profilesManager.profile(for: recipientAddress)
        }

        return recipient
    }

    func avatar() -> UIImage {
        if let groupThread = self as? TSGroupThread {
            return groupThread.groupModel.avatarOrPlaceholder
        } else {
            let avatarPlaceholder = ImageAsset.avatar_placeholder
            guard let recipientId = contactIdentifier(), let profile = SessionManager.shared.profilesManager.profile(for: recipientId) else { return avatarPlaceholder }

            return AvatarManager.shared.cachedAvatar(for: String.contentsOrEmpty(for: profile.avatar)) ?? avatarPlaceholder
        }
    }

    var muteActionTitle: String {
        return isMuted ? Localized.thread_action_unmute : Localized.thread_action_mute
    }
    
    func updateGroupMembers() {
        if let groupThread = self as? TSGroupThread {

            let contactsIDs = SessionManager.shared.profilesManager.profilesIds

            let recipientsIdsSet = Set(groupThread.recipientIdentifiers)
            let nonContactsUsersIds = recipientsIdsSet.subtracting(Set(contactsIDs))

            IDAPIClient.shared.updateContacts(with: Array(nonContactsUsersIds))

            for recipientId in groupThread.recipientIdentifiers {
                TSThread.saveRecipient(with: recipientId)
            }
        }
    }

    private func contactData(for address: String) -> Data? {
        return (Yap.sharedInstance.retrieveObject(for: address, in: ProfileKeys.storedContactKey) as? Data)
    }

    static func saveRecipient(with identifier: String) {
        TSStorageManager.shared().dbReadWriteConnection?.readWrite { transaction in

            var recipient = SignalRecipient(textSecureIdentifier: identifier, with: transaction)

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: identifier, relay: nil)
            }

            recipient?.save(with: transaction)
        }
    }
}
