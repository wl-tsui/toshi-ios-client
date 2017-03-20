import UIKit
import SweetSwift
import KeychainSwift

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

            if let user = newValue {
                let keychain = KeychainSwift()
                keychain.set(user.paymentAddress, forKey: "CurrentUserPaymentAddress")
            }

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

    public let paymentAddress: String

    public var JSONData: Data {
        return try! JSONSerialization.data(withJSONObject: self.asDict, options: [])
    }

    public var asDict: [String: Any?] {
        return [
            "token_id": self.address,
            "payment_address": self.paymentAddress,
            "username": self.username,
            "about": self.about,
            "location": self.location,
            "name": self.name,
            "avatar": self.avatarPath
        ]
    }

    init(json: [String: Any]) {
        self.address = json["token_id"] as! String
        self.paymentAddress = (json["payment_address"] as? String) ?? (json["token_id"] as! String)
        self.username = json["username"] as! String
        self.name = json["name"] as? String
        self.location = json["location"] as? String
        self.about = json["about"] as? String
        self.avatarPath = json["avatar"] as? String

        super.init()

        self.updateAvatar()
    }

    init(address: String, paymentAddress: String, username: String, name: String?, about: String?, location: String?) {
        self.address = address
        self.username = username
        self.paymentAddress = paymentAddress
        self.name = name
        self.about = about
        self.location = location
    }

    func updateAvatar() {
        guard let avatarPath = self.avatarPath else { return }
        if avatarPath.length > 0 {
            IDAPIClient.shared.downloadAvatar(path: avatarPath) { image in
                self.avatar = image
            }
        }
    }

    public func update() {
        self.updateAvatar()
        let json = self.JSONData
        User.yap.insert(object: json, for: User.storedUserKey)
    }

    public override var description: String {
        return "<User: address: \(self.address), payment address: \(self.paymentAddress), name: \(self.name), username: \(self.username)>"
    }
}
