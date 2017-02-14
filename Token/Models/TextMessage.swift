import UIKit
import JSQMessages

public class TextMessage: JSQMessage {
    public var sofaWrapper: SofaWrapper

    public var isDisplayable: Bool {
        return [.message, .paymentRequest].contains(self.sofaWrapper.type)
    }

    public override var text: String! {
        get {
            switch self.sofaWrapper.type {
            case .message:
                return (self.sofaWrapper as! SofaMessage).body
            case .paymentRequest:
                return (self.sofaWrapper as! SofaPaymentRequest).body
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
