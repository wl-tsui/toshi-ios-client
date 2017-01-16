import Foundation

public class TokenContact: NSObject, JSONDataSerialization {

    public static let collectionKey: String = "TokenContacts"

    public var address: String

    public var username: String

    public var name: String?

    public init(json: [String: Any]) {
        self.address = json["owner_address"] as! String
        self.username = json["username"] as! String

        if let custom = json["custom"] as? [String: Any] {
            self.name = custom["name"] as? String
        }

        super.init()
    }

    public override var description: String {
        return "<TokenContact: address: \(self.address), name: \(self.name ?? ""), username: \(self.username)>"
    }

    public var JSONData: Data {
        let json: [String: Any] = [
            "owner_address": self.address,
            "custom": ["name": self.name ?? ""],
            "username": self.username,
            "avatar": "",
            ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }
}
