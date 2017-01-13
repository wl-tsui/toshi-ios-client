import Foundation

public class User: NSObject {

    static let yap = Yap.sharedInstance

    static var _current: User?

    public static var current: User? {
        get {
            if let current = _current {
                return current
            } else if let user = self.yap.retrieveObject(for: "StoredUser") as? User {
                _current = user
                return user
            }

            return _current
        }
        set {
            self.yap.insert(object: newValue, for: "StoredUser")
            _current = newValue
        }
    }

    let username: String

    var name: String?

    let address: String

    init(json: [String: Any]) {
        self.address = json["owner_address"] as! String
        self.name = (json["custom"] as? [String: Any])?["name"] as? String
        self.username = json["username"] as! String

        super.init()

        User.current = self
    }

    public override var description: String {
        return "<User: address: \(self.address), name: \(self.name ?? ""), username: \(self.username)>"
    }
}
