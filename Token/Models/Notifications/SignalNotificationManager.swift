import UIKit

public class SignalNotificationManager: NSObject, NotificationsProtocol {

    static var tabbarController: TabBarController {
        get {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError("Could not find application delegate.") }
            guard let window = delegate.window else { fatalError("Could not find application window.") }
            guard let tabbarController = window.rootViewController as? TabBarController else { fatalError("Could not find tabbar root.") }

            return tabbarController
        }
    }

    public func notifyUser(for incomingMessage: TSIncomingMessage!, from name: String!, in thread: TSThread!) {
        guard UIApplication.shared.applicationState == .background || SignalNotificationManager.tabbarController.selectedViewController != SignalNotificationManager.tabbarController.messagingController else {
            return
        }

        defer { SignalNotificationManager.updateApplicationBadgeNumber() }

        let content = UNMutableNotificationContent()
        content.title = name

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
            self.tabbarController.messagingController.tabBarItem.badgeValue = "\(count)"
            self.tabbarController.messagingController.tabBarItem.badgeColor = .red
        } else {
            self.tabbarController.messagingController.tabBarItem.badgeValue = nil
        }
    }
}
