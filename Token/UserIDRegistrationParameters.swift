import Foundation
import SweetFoundation

/// Prepares user data, signs and formats the JSON properly for user ID server registration and update.
struct UserIDRegistrationParameters {
    let name: String?

    let username: String?

    let location: String?

    let about: String?

    let timestamp: Int

    let cereal: Cereal

    var payload: [String: Any] {
        var payload: [String: Any] = ["timestamp": self.timestamp]

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

    func signedParameters() -> [String: Any] {
        let message = self.stringForSigning
        let signature = self.cereal.sign(message: message)

        let params: [String: Any] = [
            "payload": self.payload,
            "address": self.cereal.address,
            "signature": "0x\(signature)",
        ]

        return params
    }

    init(name: String?, username: String?, timestamp: Int, cereal: Cereal, location: String? = nil, about: String? = nil) {
        self.name = name
        self.username = username
        self.cereal = cereal

        self.timestamp = timestamp

        self.location = location
        self.about = about
    }
}
