import Foundation
import UIKit

typealias MessageAction = () -> Void

struct MessageButtonModel {
    let type: MessageType
    let title: String
    let icon: String

    enum MessageType {
        case approve
        case decline
    }

    static var approve: MessageButtonModel {
        return MessageButtonModel(type: .approve, title: "Approve", icon: "approve")
    }

    static var decline: MessageButtonModel {
        return MessageButtonModel(type: .decline, title: "Decline", icon: "decline")
    }
}

enum Status {
    case positive(String)
    case negative(String)
    case neutral(String)
}

enum MessageType {
    case simple
    case image
    case paymentRequest
    case payment
    case status
}

struct MessageModel {
    private let message: Message

    var type: MessageType
    var title: String?
    var subtitle: String?
    let text: String?
    let isOutgoing: Bool

    var image: UIImage? {
        if self.message.image != nil {
            return self.message.image
        } else {
            return nil
        }
    }

    let buttonModels: [MessageButtonModel]?
    var status: Status?
    var isActionable: Bool?
    var signalMessage: TSMessage?
    var sofaWrapper: SofaWrapper?

    public var fiatValueString: String?
    public var ethereumValueString: String?

    init(message: Message) {
        self.message = message

        self.isOutgoing = message.isOutgoing

        if let title = message.title, !title.isEmpty {
            self.title = title
        } else {
            self.title = nil
        }

        self.fiatValueString = nil
        self.ethereumValueString = nil

        self.subtitle = message.subtitle
        self.text = message.text

        self.signalMessage = message.signalMessage
        self.sofaWrapper = message.sofaWrapper

        if message.sofaWrapper?.type == .paymentRequest {
            self.type = .paymentRequest
            self.buttonModels = message.isOutgoing ? nil : [.approve, .decline]

            self.fiatValueString = message.fiatValueString
            self.ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                self.title = "Request for \(fiatValueString)"
            }
            self.subtitle = message.ethereumValueString

        } else if message.sofaWrapper?.type == .payment {
            self.type = .payment
            self.buttonModels = nil

            self.fiatValueString = message.fiatValueString
            self.ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                self.title = "Payment for \(fiatValueString)"
            }
            self.subtitle = message.ethereumValueString

        } else {
            self.type = .simple
            self.buttonModels = nil
        }

        self.status = nil

        self.isActionable = self.buttonModels != nil
    }

    var imageOnly: Bool {
        guard let text = self.text else { return self.image != nil }
        return self.image != nil && text.isEmpty
    }
}
