import Foundation
import UserNotifications

public class BackgroundNotificationHandler: NSObject {

    public static func handle(_ notification: UNNotification, _ completion: @escaping((_ options: UNNotificationPresentationOptions) -> Void)) {

        let body = notification.request.content.body

        if SofaType(sofa: body) == .none {
            completion([.badge, .sound, .alert])

            return
        }

        if SofaWrapper.wrapper(content: body) as? SofaMessage != nil {
            completion([.badge, .sound, .alert])

            return
        }

        if let payment = SofaWrapper.wrapper(content: body) as? SofaPayment, payment.status == .confirmed {
            self.enqueueLocalNotification(for: payment)
            completion([])

            return
        }

        completion([.badge, .sound, .alert])
    }

    static func enqueueLocalNotification(for payment: SofaPayment) {
        let content = UNMutableNotificationContent()
        content.title = "Payment received!"

        let value = EthereumConverter.dollarValueString(forWei: payment.value)
        content.body = "You've received \(value)."

        content.sound = UNNotificationSound(named: "PN.m4a")

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: content.title, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
