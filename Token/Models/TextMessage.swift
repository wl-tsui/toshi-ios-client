import UIKit
import SweetFoundation
import JSQMessages

public class TextMessage: JSQMessage {
    public var sofaWrapper: SofaWrapper

    public var isDisplayable: Bool {
        return [.message, .paymentRequest, .payment].contains(self.sofaWrapper.type)
    }

    public override var text: String! {
        get {
            switch self.sofaWrapper.type {
            case .message:
                return (self.sofaWrapper as! SofaMessage).body
            case .paymentRequest:
                let body = (self.sofaWrapper as! SofaPaymentRequest).body
                if body.length > 0 {
                    return body
                }
                return "Payment requested without message."
            case .payment:
                return "Should be an empty string here but layout breaks for now."
            default:
                return self.sofaWrapper.content
            }
        }
    }

    public init(senderId: String, displayName: String, date: Date = Date(), isMedia: Bool = false, sofaWrapper: SofaWrapper, shouldProcess: Bool = false) {
        self.sofaWrapper = sofaWrapper

        super.init(senderId: senderId, senderDisplayName: displayName, date: date, text: "", isActionable: false)

        let isIncoming = self.senderId != User.current!.address

        self.isActionable = shouldProcess && isIncoming && (self.sofaWrapper.type == .paymentRequest)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
