import UIKit
import SweetSwift

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

    public var name: String = "" {
        didSet {
            self.update()
        }
    }

    public var about: String = "" {
        didSet {
            self.update()
        }
    }

    public var location: String = "" {
        didSet {
            self.update()
        }
    }

    public var avatarPath: String = "" {
        didSet {
            self.update()
        }
    }

    var hasCustomFields: Bool {
        get {
            return (self.about.length > 0 || self.location.length > 0 || self.name.length > 0)
        }
    }

    public var avatar: UIImage?

    public let address: String

    public var JSONData: Data {
        let json: [String: Any] = [
            "owner_address": self.address,
            "custom": ["name": self.name, "location": self.location, "about": self.about],
            "username": self.username,
            "avatar": self.avatarPath,
        ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    init(json: [String: Any]) {
        self.address = json["owner_address"] as! String
        self.username = json["username"] as! String

        if let json = json["custom"] as? [String: Any] {
            self.name = json["name"] as? String ?? ""
            self.location = json["location"] as? String ?? ""
            self.about = json["about"] as? String ?? ""
        }

        super.init()
    }

    init(address: String, username: String, name: String?, about: String?, location: String?) {
        self.address = address
        self.username = username

        self.name = name ?? ""
        self.about = about ?? ""
        self.location = location ?? ""
    }

    public func update() {
        let json = self.JSONData
        User.yap.insert(object: json, for: User.storedUserKey)
    }

    public func asRequestParameters() -> [String: Any] {
        var params: [String: Any] = [
            "username": self.username,
        ]

        if self.hasCustomFields {
            var custom = [String: Any]()
            if self.about.length > 0 {
                custom["about"] = self.about
            }
            if self.location.length > 0 {
                custom["location"] = self.location
            }
            if self.name.length > 0 {
                custom["name"] = self.name
            }

            params["custom"] = custom
        }

        return params
    }

    public override var description: String {
        return "<User: address: \(self.address), name: \(self.name), username: \(self.username)>"
    }
}

// Balance display, should move this somewhere else. Probably a UnitConverter struct.
extension User {
    public static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    public static var weisToEtherPowerOf10Constant: Int16 {
        get {
            return Int16(self.weisToEtherConstant.stringValue.length - 1)
        }
    }

    public static func ethereumValueString(forEther balance: NSDecimalNumber) -> String {
        return "\(balance.toDecimalString) ETH"
    }

    public static func dollarValueString(forWei balance: NSDecimalNumber) -> String {
        let ether = balance.dividing(by: self.weisToEtherConstant)
        // Conversion from https://www.coinbase.com/charts
        let currentUSDConversion = NSDecimalNumber(decimal: EthereumAPIClient.shared.exchangeRate)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currencyAccounting
        numberFormatter.locale = Locale(identifier: "en_US")

        let usd: NSDecimalNumber = currentUSDConversion.multiplying(by: ether)

        return numberFormatter.string(from: usd)!
    }

    // TODO: Add unit tests for this.
    public static func balanceAttributedString(for balance: NSDecimalNumber) -> NSAttributedString {
        let usdText = self.dollarValueString(forWei: balance)
        let etherText = self.ethereumValueString(forEther: balance.dividing(by: self.weisToEtherConstant).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior))

        let text = usdText + " · " + etherText
        let coloredPart = etherText
        let range = (text as NSString).range(of: coloredPart)

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.greyTextColor, range: range)
        
        return attributedString
    }

}
