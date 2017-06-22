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

import UIKit

public class SignalNotificationManager: NSObject, NotificationsProtocol {

    static var tabbarController: TabBarController? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window else { return nil }

        return window.rootViewController as? TabBarController
    }

    public func notifyUser(for incomingMessage: TSIncomingMessage!, in thread: TSThread!, contactsManager: ContactsManagerProtocol!) {

        guard UIApplication.shared.applicationState == .background || SignalNotificationManager.tabbarController?.selectedViewController != SignalNotificationManager.tabbarController?.messagingController else {
            return
        }

        defer { SignalNotificationManager.updateApplicationBadgeNumber() }

        let content = UNMutableNotificationContent()
        content.title = thread.name()
        content.threadIdentifier = thread.uniqueId

        if let body = incomingMessage.body, let sofa = SofaWrapper.wrapper(content: body) as? SofaMessage {
            content.body = sofa.body
        } else {
            content.body = "New message."
        }

        content.sound = UNNotificationSound(named: "PN.m4a")

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }

    public func notifyUser(for error: TSErrorMessage!, in thread: TSThread!) {
        print("Error: \(error), in thread: \(thread).")
    }

    public static func updateApplicationBadgeNumber() {
        let count = Int(TSMessagesManager.shared().unreadMessagesCount())
        UIApplication.shared.applicationIconBadgeNumber = count

        if count > 0 {
            self.tabbarController?.messagingController.tabBarItem.badgeValue = "\(count)"
            self.tabbarController?.messagingController.tabBarItem.badgeColor = .red
        } else {
            self.tabbarController?.messagingController.tabBarItem.badgeValue = nil
        }
    }
}
