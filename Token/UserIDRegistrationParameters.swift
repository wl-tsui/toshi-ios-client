import Foundation
import SweetFoundation

struct UserIDRegistrationParameters {
    let name: String
    let username: String

    let cereal: Cereal

    var payload: [String: Any]  {
        return [
            "custom": [
                "name": self.name
            ],
            "username": self.username,
            "timestamp": UInt64(Date().timeIntervalSince1970)
        ]
    }

    var stringForSigning: String {
        let ordered = OrderedSerializer.string(from: self.payload)
        print(ordered)

        return ordered
    }

    func signedParameters() -> [String: Any] {
        let message = self.stringForSigning
        let signature = self.cereal.sign(message: message)

        let params: [String: Any] = [
            "payload": self.payload,
            "address": self.cereal.address,
            "signature": "0x\(signature)"
        ]

        print(params)

        return params
    }

    init(name: String?, username: String?, cereal: Cereal) {
        self.name = name ?? ""
        self.username = username ?? ""
        self.cereal = cereal
    }
}
