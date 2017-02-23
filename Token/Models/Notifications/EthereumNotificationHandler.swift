import Foundation

class EthereumNotificationHandler: NSObject {
    public static func handlePayment(_ userInfo: [String: Any], completion: @escaping((_ state: UIBackgroundFetchResult) -> Void)) {
        if userInfo["type"] as? String == "signal_message" { return }

        guard let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: Any], let body = alert["body"] as? String else {
            completion(.noData)

            return
        }

        guard SofaWrapper.wrapper(content: body) as? SofaPayment != nil else {
            completion(.noData)

            return
        }

        EthereumAPIClient.shared.getBalance(address: Cereal().paymentAddress) { (balance, error) in
            print(balance)
            print(error?.localizedDescription ?? "")

            completion(.newData)
        }
    }
}
