import Foundation

public class User: NSObject {

    static var current: User?

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
