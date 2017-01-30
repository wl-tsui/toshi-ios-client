import Foundation
import SweetFoundation

/// Prepares user data, signs and formats the JSON properly for user ID server registration and update.
struct UserIDRegistrationParameters {
    let name: String?

    let username: String?

    let location: String?

    let about: String?

    let cereal: Cereal

    var payload: [String: Any] {
        var payload = [String: Any]()

        if let username = self.username {
            payload["username"] = username
        }

        if self.hasCustom {
            payload["custom"] = self.customPayload
        }

        return payload
    }

    var hasCustom: Bool {
        return ((self.name != nil) || (self.location != nil) || (self.about != nil))
    }

    var customPayload: [String: Any] {
        var custom = [String: Any]()

        if let name = self.name {
            custom["name"] = name
        }

        if let location = self.location {
            custom["location"] = location
        }

        if let about = self.about {
            custom["about"] = about
        }

        return custom
    }

    var stringForSigning: String {
        return OrderedSerializer.string(from: self.payload)
    }

    init(name: String?, username: String?, cereal: Cereal, location: String? = nil, about: String? = nil) {
        self.name = name
        self.username = username
        self.cereal = cereal

        self.location = location
        self.about = about
    }
}
