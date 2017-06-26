// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import SweetSwift

public extension NSNotification.Name {
    public static let currentUserUpdated = NSNotification.Name(rawValue: "currentUserUpdated")
}

public typealias UserInfo = (address: String, paymentAddress: String?, avatarPath: String?, name: String?, username: String?, isLocal: Bool)

public class TokenUser: NSObject, NSCoding {

    struct Constants {
        static let name = "name"
        static let username = "username"
        static let address = "token_id"
        static let paymentAddress = "payment_address"
        static let location = "location"
        static let about = "about"
        static let avatar = "avatar"
        static let isApp = "is_app"
        static let verified = "verified"
    }

    static let viewExtensionName = "TokenContactsDatabaseViewExtensionName"
    static let favoritesCollectionKey: String = "TokenContacts"

    fileprivate static let storedUserKey = "StoredUser"

    public static let storedContactKey = "storedContactKey"

    var category = ""

    var balance = NSDecimalNumber.zero

    var verified: Bool = false {
        didSet {
            self.save()
        }
    }

    private(set) var name = ""

    var displayUsername: String {
        return "@\(self.username)"
    }
    private(set) var username = ""
    private(set) var about = ""
    private(set) var location = ""
    private(set) var avatarPath = ""

    private(set) var address = ""
    private(set) var paymentAddress = ""
    private(set) var isApp: Bool = false

    fileprivate static var _current: TokenUser?
    fileprivate(set) static var current: TokenUser? {
        get {
            if self._current == nil {
                self._current = self.retrieveCurrentUserFromStore()
            }

            return self._current
        }
        set {
            guard self._current != newValue else { return }

            newValue?.update()

            if let user = newValue {
                user.save()
            }

            self._current = newValue
            NotificationCenter.default.post(name: .currentUserUpdated, object: nil)
        }
    }

    var isBlocked: Bool {
        let blockingManager = OWSBlockingManager.shared()

        return blockingManager.blockedPhoneNumbers().contains(self.address)
    }

    var isCurrentUser: Bool {
        return self.address == Cereal.shared.address
    }

    public var JSONData: Data {
        return try! JSONSerialization.data(withJSONObject: self.asDict, options: [])
    }

    var asDict: [String: Any] {
        return [
            Constants.address: self.address,
            Constants.paymentAddress: self.paymentAddress,
            Constants.username: self.username,
            Constants.about: self.about,
            Constants.location: self.location,
            Constants.name: self.name,
            Constants.avatar: self.avatarPath,
            Constants.isApp: self.isApp,
            Constants.verified: self.verified,
        ]
    }

    var userInfo: UserInfo {
        return UserInfo(address: self.address, paymentAddress: self.paymentAddress, avatarPath: self.avatarPath, name: self.name, username: self.displayUsername, isLocal: true)
    }

    public override var description: String {
        return "<User: address: \(self.address), payment address: \(self.paymentAddress), name: \(self.name), username: \(username), avatarPath: \(self.avatarPath)>"
    }

    static func name(from username: String) -> String {
        return username.hasPrefix("@") ? username.substring(from: username.index(after: username.startIndex)) : username
    }

    static func user(with data: Data, shouldUpdate: Bool = true) -> TokenUser? {
        guard let deserialised = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let json = deserialised as? [String: Any] else { return nil }

        return TokenUser(json: json, shouldSave: shouldUpdate)
    }

    public init(json: [String: Any], shouldSave: Bool = true) {
        super.init()

        self.update(json: json, updateAvatar: true, shouldSave: shouldSave)

        self.setupNotifications()
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let jsonData = aDecoder.decodeObject(forKey: "jsonData") as? Data else { return nil }
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData, options: []), let json = deserialised as? [String: Any] else { return nil }

        self.init(json: json)
    }

    @objc(encodeWithCoder:) public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.JSONData, forKey: "jsonData")
    }

    func update(json: [String: Any], updateAvatar _: Bool = false, shouldSave: Bool = true) {
        self.address = json[Constants.address] as! String
        self.paymentAddress = (json[Constants.paymentAddress] as? String) ?? (json[Constants.address] as! String)
        self.username = json[Constants.username] as! String
        self.name = json[Constants.name] as? String ?? self.name
        self.location = json[Constants.location] as? String ?? self.location
        self.about = json[Constants.about] as? String ?? self.about
        self.avatarPath = json[Constants.avatar] as? String ?? self.avatarPath
        self.isApp = json[Constants.isApp] as? Bool ?? self.isApp

        self.verified = json[Constants.verified] as? Bool ?? self.verified

        if shouldSave {
            self.save()
        }
    }

    func update(avatar _: UIImage, avatarPath: String) {
        self.avatarPath = avatarPath

        self.save()
    }

    func update(username: String? = nil, name: String? = nil, about: String? = nil, location: String? = nil) {
        self.username = username ?? self.username
        self.name = name ?? self.name
        self.about = about ?? self.about
        self.location = location ?? self.location

        self.save()
    }

    public static func createOrUpdateCurrentUser(with json: [String: Any]) {
        guard self.current != nil else {
            self.current = TokenUser(json: json)
            return
        }

        self.current?.update(json: json)
    }

    public static func retrieveCurrentUser() {
        self.current = self.retrieveCurrentUserFromStore()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateIfNeeded), name: IDAPIClient.didFetchContactInfoNotification, object: nil)
    }

    @objc private func updateIfNeeded(_ notification: Notification) {
        guard let tokenContact = notification.object as? TokenUser else { return }
        guard tokenContact.address == self.address else { return }

        if self.name == tokenContact.name && self.username == tokenContact.username && self.location == tokenContact.location && self.about == tokenContact.about {
            return
        }

        self.update(username: tokenContact.username, name: tokenContact.name, about: tokenContact.about, location: tokenContact.location)
    }

    private func save() {
        if self.isCurrentUser {
            Yap.sharedInstance.insert(object: self.JSONData, for: TokenUser.storedUserKey)
        } else {
            Yap.sharedInstance.insert(object: self.JSONData, for: self.address, in: TokenUser.storedContactKey)
        }
    }

    private static func retrieveCurrentUserFromStore() -> TokenUser? {
        var user: TokenUser?

        if self._current == nil, let userData = (Yap.sharedInstance.retrieveObject(for: TokenUser.storedUserKey) as? Data),
            let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
            var json = deserialised as? [String: Any] {

            // Because of payment address migration, we have to override the stored payment address.
            // Otherwise users will be sending payments to the wrong address.
            if json[Constants.paymentAddress] as? String != Cereal.shared.paymentAddress {
                json[Constants.paymentAddress] = Cereal.shared.paymentAddress
            }

            user = TokenUser(json: json)
        }

        return user
    }
}
