import Foundation

public class SofaWrapper {
    let messagePrefix = "SOFA::Message:"

    public var content: String

    public lazy var body: String = {
        if self.content.hasPrefix(self.messagePrefix) {
            let sofaBody = self.content.replacingOccurrences(of: self.messagePrefix, with: "")
            let data = sofaBody.data(using: .utf8)!

            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else { return self.content }
            guard let json = jsonObject as? [String: Any] else { return "" }

            if let messageText = json["body"] as? String {
                return messageText
            }
        }

        return ""
    }()

    public init(sofaContent: String) {
        self.content = sofaContent
    }

    public init(messageBody: String?) {
        self.content = "\(self.messagePrefix){\"body\":\"\(messageBody ?? "")\"}"
    }
}
