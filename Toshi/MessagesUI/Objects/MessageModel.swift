import Foundation
import UIKit

typealias MessageAction = ((MessageButtonModel.MessageType?) -> Void)

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

    var identifier: String {
        return message.uniqueIdentifier()
    }

    var image: UIImage? {
        if message.image != nil {
            return message.image
        } else {
            return nil
        }
    }

    var buttonModels: [MessageButtonModel]?
    var status: Status?
    var isActionable: Bool?
    var signalMessage: TSMessage?
    var sofaWrapper: SofaWrapper?

    public var fiatValueString: String?
    public var ethereumValueString: String?

    init(message: Message) {
        self.message = message

        isOutgoing = message.isOutgoing

        if let title = message.title, !title.isEmpty {
            self.title = title
        } else {
            title = nil
        }

        fiatValueString = nil
        ethereumValueString = nil

        subtitle = message.subtitle
        text = message.text

        signalMessage = message.signalMessage
        sofaWrapper = message.sofaWrapper

        if message.sofaWrapper?.type == .paymentRequest {
            type = .paymentRequest
            buttonModels = message.isOutgoing ? nil : [.approve, .decline]

            fiatValueString = message.fiatValueString
            ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                title = "Request for \(fiatValueString)"
            }
            subtitle = message.ethereumValueString

        } else if message.sofaWrapper?.type == .payment {
            type = .payment
            buttonModels = nil

            fiatValueString = message.fiatValueString
            ethereumValueString = message.ethereumValueString

            if let fiatValueString = message.fiatValueString {
                title = "Payment for \(fiatValueString)"
            }
            subtitle = message.ethereumValueString

        } else if message.image != nil {
            type = .image
            buttonModels = nil
        } else {
            type = .simple
            buttonModels = nil
        }

        status = nil

        isActionable = buttonModels != nil
    }

    var imageOnly: Bool {
        guard let text = self.text else { return image != nil }
        return image != nil && text.isEmpty
    }
}
