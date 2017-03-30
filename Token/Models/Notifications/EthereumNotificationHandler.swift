import Foundation
import UserNotifications

public extension NSNotification.Name {
    public static let ethereumBalanceUpdateNotification = NSNotification.Name(rawValue: "EthereumBalanceUpdateNotification")

    public static let ethereumPaymentUnconfirmedNotification = NSNotification.Name(rawValue: "EthereumPaymentUnconfirmedNotification")
    public static let ethereumPaymentConfirmedNotification = NSNotification.Name(rawValue: "EthereumPaymentConfirmedNotification")
    public static let ethereumPaymentErrorNotification = NSNotification.Name(rawValue: "EthereumPaymentErrorNotification")
}

let paymentStatusMap = [
    SofaPayment.Status.unconfirmed: NSNotification.Name.ethereumPaymentUnconfirmedNotification,
    SofaPayment.Status.confirmed: NSNotification.Name.ethereumPaymentConfirmedNotification,
    SofaPayment.Status.error: NSNotification.Name.ethereumPaymentErrorNotification,
]

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

            guard let sofa = SofaWrapper.wrapper(content: body) as? SofaPayment else {
                completion(.noData)

                return
            }

            if UIApplication.shared.applicationState == .active {
                let balanceNotification = Notification(name: .ethereumBalanceUpdateNotification, object: balance, userInfo: nil)
                NotificationCenter.default.post(balanceNotification)

                guard let notificationName = paymentStatusMap[sofa.status] else { return }
                let paymentNotification = Notification(name: notificationName, object: sofa, userInfo: nil)
                NotificationCenter.default.post(paymentNotification)

                return
            }

            if sofa.status == .unconfirmed {
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
}
