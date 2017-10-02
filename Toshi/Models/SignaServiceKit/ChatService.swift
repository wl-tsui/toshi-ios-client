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

public protocol ChatServiceErrorHandler: class {

    func didFailToSetup()
}

final class ChatService: NSObject {

    @objc private(set) var networkManager: TSNetworkManager?
    @objc private(set) var contactsManager: ContactsManager?
    @objc private(set) var contactsUpdater: ContactsUpdater?
    @objc private(set) var messageSender: MessageSender?
    private(set) var incomingMessageReadObserver: OWSIncomingMessageReadObserver?

    @objc static let shared = ChatService()

    var errorHandler: ChatServiceErrorHandler?

    @objc func setup(accountName: String, isFirstLaunch: Bool) {
        OWSSignalService.sharedInstance()

        networkManager = TSNetworkManager.sharedManager() as? TSNetworkManager
        contactsManager = ContactsManager()
        contactsUpdater = ContactsUpdater.shared()

        let storageManager = TSStorageManager.shared()
        storageManager.setup(accountName: accountName, isFirstLaunch: isFirstLaunch)

        guard let networkManager = self.networkManager, let contactsManager = self.contactsManager, let contactsUpdater = self.contactsUpdater else {
            self.errorHandler?.didFailToSetup()
            return
        }

        self.messageSender = MessageSender(networkManager: networkManager, storageManager: storageManager, contactsManager: contactsManager, contactsUpdater: contactsUpdater)

        guard let messageSender = self.messageSender else {
            self.errorHandler?.didFailToSetup()
            return
        }

        let textSecureEnv: TextSecureKitEnv = TextSecureKitEnv()
        textSecureEnv.setup(callMessageHandler: EmptyCallHandler(), contactsManager: contactsManager, messageSender: messageSender, notificationsManager: SignalNotificationManager(), preferences: self)
        TextSecureKitEnv.setShared(textSecureEnv)

        self.incomingMessageReadObserver = OWSIncomingMessageReadObserver(storageManager: storageManager, messageSender: messageSender)
        self.incomingMessageReadObserver?.startObserving()
    }

    @objc func freeUp() {

        self.networkManager = nil
        self.contactsManager = nil
        self.contactsUpdater = nil
        self.messageSender = nil
        TextSecureKitEnv.setShared(nil)
        self.incomingMessageReadObserver = nil
    }
}

extension ChatService: TSPreferences {

    func isSendingIdentityApprovalRequired() -> Bool {
        return false
    }
}

