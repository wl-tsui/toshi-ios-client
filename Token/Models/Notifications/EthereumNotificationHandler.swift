import Foundation
import UserNotifications

public extension NSNotification.Name {
    public static let ethereumPaymentConfirmationNotification = NSNotification.Name(rawValue: "EthereumPaymentConfirmationNotification")
}

class EthereumNotificationHandler: NSObject {

    public static func handlePayment(_ userInfo: [String: Any], completion: @escaping ((_ state: UIBackgroundFetchResult) -> Void)) {
        if userInfo["type"] as? String == "signal_message" { return }

        guard let body = userInfo["sofa"] as? String else {
            completion(.noData)

            return
        }

        guard SofaWrapper.wrapper(content: body) as? SofaPayment != nil else {
            completion(.noData)

            return
        }

        EthereumAPIClient.shared.getBalance(address: Cereal().paymentAddress) { balance, error in
            print(balance)
            print(error?.localizedDescription ?? "")

            defer {
                completion(.newData)
            }

            guard let sofa = SofaWrapper.wrapper(content: body) as? SofaPayment, sofa.status == .confirmed else {
                completion(.noData)

                return
            }

            if UIApplication.shared.applicationState == .active {
                let notification = Notification(name: .ethereumPaymentConfirmationNotification, object: balance, userInfo: nil)
                NotificationCenter.default.post(notification)

                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Payment"

            if sofa.recipientAddress == User.current?.paymentAddress {
                content.body = "Payment received: \(EthereumConverter.fiatValueString(forWei: sofa.value))."
            } else {
                content.body = "Payment sent: \(EthereumConverter.fiatValueString(forWei: sofa.value))."
            }

            content.sound = UNNotificationSound(named: "PN.m4a")

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: content.title, content: content, trigger: trigger)

            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: nil)
        }
    }
}
