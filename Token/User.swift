import UIKit

public protocol JSONDataSerialization {
    var JSONData: Data { get }
}

/// Current User. Responsible for current session management.
public class User: NSObject, JSONDataSerialization {

    static let yap = Yap.sharedInstance

    private static let storedUserKey = "StoredUser"

    static var _current: User?

    public static var current: User? {
        get {
            if let userData = (self.yap.retrieveObject(for: User.storedUserKey) as? Data), _current == nil,
                let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
                let json = deserialised as? [String: Any] {

                _current = User(json: json)
            }

            return _current
        }
        set {
            newValue?.update()

            _current = newValue
        }
    }

    public var username: String {
        didSet {
            self.update()
        }
    }

    public var name: String? {
        didSet {
            self.update()
        }
    }

    public var about: String? {
        didSet {
            self.update()
        }
    }

    public var location: String? {
        didSet {
            self.update()
        }
    }

    public var avatarPath: String? {
        didSet {
            self.update()
        }
    }

    public var avatar: UIImage?

    public let address: String

    public var JSONData: Data {
        let json: [String: Any] = [
            "owner_address": self.address,
            "custom": ["name": self.name ?? "", "location": self.location ?? "", "about": self.about ?? ""],
            "username": self.username,
            "avatar": self.avatarPath ?? "",
            ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    init(json: [String: Any]) {
        self.address = json["owner_address"] as! String
        self.username = json["username"] as! String

        if let json = json["custom"] as? [String: Any] {
            self.name = json["name"] as? String
            self.location = json["location"] as? String
            self.about = json["about"] as? String
        }

        super.init()
    }

    init(address: String, username: String, name: String?, about: String?, location: String?) {
        self.address = address
        self.name = name
        self.about = about
        self.username = username
        self.location = location
    }

    public func update() {
        let json = self.JSONData
        User.yap.insert(object: json, for: User.storedUserKey)
    }

    public override var description: String {
        return "<User: address: \(self.address), name: \(self.name ?? ""), username: \(self.username)>"
    }
}
