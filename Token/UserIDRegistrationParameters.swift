import Foundation
import SweetFoundation

struct UserIDRegistrationParameters {
    let name: String?
    let username: String?

    let cereal: Cereal

    var payload: [String: Any] {
        var payload: [String: Any] = ["timestamp": UInt64(Date().timeIntervalSince1970)]

        if let username = self.username {
            payload["username"] = username
        }

        if let name = self.name {
            payload["custom"] = ["name": name]
        }

        return payload
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

    init(name: String?, username: String?, cereal: Cereal) {
        self.name = name
        self.username = username
        self.cereal = cereal
    }
}
