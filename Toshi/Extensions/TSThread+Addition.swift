// Copyright (c) 2017 Token Browser, Inc
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

    func avatar() -> UIImage? {
        if isGroupThread() {
            return (self as? TSGroupThread)?.groupModel.groupImage
        } else {
            return image()
        }
    }
    
    func updateGroupMembers() {
        if let groupThread = self as? TSGroupThread {

            guard  let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let contactsIDs = appDelegate.contactsManager.tokenContacts.map { $0.address }

            let recipientsIdsSet = Set(groupThread.recipientIdentifiers)
            let nonContactsUsersIds = recipientsIdsSet.subtracting(Set(contactsIDs))

            IDAPIClient.shared.updateContacts(with: Array(nonContactsUsersIds))

            for recipientId in groupThread.recipientIdentifiers {
                TSThread.saveRecipient(with: recipientId)
            }
        }
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
