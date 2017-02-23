import Foundation

class SignalNotificationHandler: NSObject {
    public static func handleMessage(_ userInfo: [String: Any], completion: @escaping((_ state: UIBackgroundFetchResult) -> Void)) {
        guard userInfo["type"] as? String == "signal_message" else { return }

        TSSocketManager.becomeActive(fromBackgroundExpectMessage: true)

        DispatchQueue.main.asyncAfter(seconds: 15) {
            completion(.newData)
        }
    }
}
