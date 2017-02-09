import Foundation

public enum SofaType: String {
    case none = ""
    case message = "SOFA::Message:"
    case command = "SOFA::Command:"
    case metadataRequest = "SOFA::InitRequest:"
    case metadataResponse = "SOFA::Init:"
    case paymentRequest = "SOFA::PaymentRequest:"
    case payment = "SOFA::Payment:"

    init(sofa: String) {
        if sofa.hasPrefix(SofaType.message.rawValue) {
            self = .message
        } else if sofa.hasPrefix(SofaType.command.rawValue) {
            self = .command
        } else if sofa.hasPrefix(SofaType.metadataRequest.rawValue) {
            self = .metadataRequest
        } else if sofa.hasPrefix(SofaType.metadataResponse.rawValue) {
            self = .metadataResponse
        } else if sofa.hasPrefix(SofaType.paymentRequest.rawValue) {
            self = .paymentRequest
        } else if sofa.hasPrefix(SofaType.payment.rawValue) {
            self = .payment
        } else {
            self = .none
        }
    }
}

public protocol SofaWrapperProtocol {
    var type: SofaType { get }
}

open class SofaWrapper: SofaWrapperProtocol {
    public var type: SofaType {
        return .none
    }

    open var content: String = ""

    open var json: [String: Any] {
        get {
            let sofaBody = self.content.replacingOccurrences(of: self.type.rawValue, with: "")
            let data = sofaBody.data(using: .utf8)!

            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else { return [String: Any]() }
            guard let json = jsonObject as? [String: Any] else { return [String: Any]() }

            return json
        }
    }

    public static func wrapper(content: String) -> SofaWrapper {
        switch SofaType(sofa: content) {
        case .message:
            return SofaMessage(content: content)
        case .command:
            return SofaCommand(content: content)
        case .metadataRequest:
            return SofaMetadataRequest(content: content)
        case .metadataResponse:
            return SofaMetadataResponse(content: content)
        case .paymentRequest:
            return SofaPaymentRequest(content: content)
        case .payment:
            return SofaPayment(content: content)
        case .none:
            return SofaWrapper(content: "") // should probaby crash instead
        }
    }

    public init(content: String) {
        self.content = content
    }

    public init(content json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { fatalError() }
        guard let jsonString = String(data: data, encoding: .utf8) else { fatalError() }

        self.content = self.type.rawValue + jsonString
    }
}

open class SofaMessage: SofaWrapper {
    public override var type: SofaType {
        return .message
    }

    open lazy var body: String = {
        guard self.content.hasPrefix(self.type.rawValue) else {
            fatalError("Creating SofaMessage with invalid type!")
        }

        if let messageText = self.json["body"] as? String {
            return messageText
        }

        return ""
    }()
}

/// SOFA::Command:{
//      "body": "Timetable",
//      "value": "timetable"
//  }
open class SofaCommand: SofaWrapper {
    public override var type: SofaType {
        return .command
    }
}

/// App receives that with list of values it needs to continue.
/// Answered with a SOFA::Init message (SofaMetadataResponse).
open class SofaMetadataRequest: SofaWrapper {
    public override var type: SofaType {
        return .metadataRequest
    }

    open lazy var values: [String] = {
        guard self.content.hasPrefix(self.type.rawValue) else {
            fatalError("Creating SofaMessage with invalid type!")
        }

        if let values = self.json["values"] as? [String] {
            return values
        }

        return [String]()
    }()
}

// Each key is a value that came from the init request as stated above.
// Example: SofaMetadataResponse(contant: ["paymentAddress": "0xa2a0134f1df987bc388dbcb635dfeed4ce497e2a", "language": "en"])
open class SofaMetadataResponse: SofaWrapper {
    public override var type: SofaType {
        return .metadataResponse
    }

    public convenience init(metadataRequest: SofaMetadataRequest) {
        var response = [String: Any]()
        for value in metadataRequest.values {
            if value == "paymentAddress" {
                response[value] = User.current!.address
            } else if value == "language" {
                let locale = Locale.current
                response[value] = locale.identifier
            }
        }

        self.init(content: response)
    }
}

open class SofaPaymentRequest: SofaWrapper {
    public override var type: SofaType {
        return .paymentRequest
    }

    public var body: String {
        guard self.content.hasPrefix(self.type.rawValue) else {
            fatalError("Creating SofaMessage with invalid type!")
        }

        if let messageText = self.json["body"] as? String {
            return messageText
        }

        return ""
    }
}

open class SofaPayment: SofaWrapper {
    public override var type: SofaType {
        return .payment
    }
}
