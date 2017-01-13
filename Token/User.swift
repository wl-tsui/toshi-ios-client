import UIKit

public class User: NSObject {

    static let yap = Yap.sharedInstance

    static var _current: User?

    public static var current: User? {
        get {
            if let userData = (self.yap.retrieveObject(for: "StoredUser") as? Data), _current == nil,
                let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
                let json = deserialised as? [String: Any] {

                _current = User(json: json)
            }

            return _current
        }
        set {
            let json = newValue?.asJSONData
            self.yap.insert(object: json, for: "StoredUser")

            _current = newValue
        }
    }

    public let username: String

    public var name: String?

    public let address: String

    public var avatar: UIImage?

    public var avatarPath: String?

    var asJSONData: Data {
        let json: [String: Any] = [
            "owner_address": self.address,
            "custom": ["name": self.name ?? ""],
            "username": self.username,
            "avatar": self.avatarPath ?? "",
        ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    init(json: [String: Any]) {
        self.address = json["owner_address"] as! String
        self.name = (json["custom"] as? [String: Any])?["name"] as? String
        self.username = json["username"] as! String

        super.init()
    }

    public override var description: String {
        return "<User: address: \(self.address), name: \(self.name ?? ""), username: \(self.username)>"
    }
}
