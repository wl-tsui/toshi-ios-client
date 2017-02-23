import UserNotifications
import KeychainSwift

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = self.bestAttemptContent {
            if let sofa = SofaWrapper.wrapper(content: bestAttemptContent.body) as? SofaPayment {

                let keychain = KeychainSwift()
                let paymentAddress = keychain.get("CurrentUserPaymentAddress")

                if paymentAddress == sofa.recipientAddress {
                    bestAttemptContent.body = "Payment received: \(EthereumConverter.dollarValueString(forWei: sofa.value))."
                } else {
                    bestAttemptContent.body = "Payment sent: \(EthereumConverter.dollarValueString(forWei: sofa.value))."
                }


            }

            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = self.contentHandler, let bestAttemptContent = self.bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
