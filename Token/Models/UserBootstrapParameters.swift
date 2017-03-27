import Foundation
import SweetFoundation

let DeviceSpecificPassword = "1231231"

/// Prepares user keys and data, signs and formats it properly as JSON to bootstrap a chat user.
public class UserBootstrapParameter {
    public let identityKey: String

    public let lastResortPreKey: PreKeyRecord

    public let password: String

    public let prekeys: [PreKeyRecord]

    public let registrationId: UInt32

    public let signalingKey: String

    public let signedPrekey: SignedPreKeyRecord

    lazy var payload: [String: Any] = {
        var prekeys = [[String: Any]]()

        for prekey in self.prekeys {
            let prekeyParam: [String: Any] = [
                "keyId": prekey.id,
                "publicKey": ((prekey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString(),
            ]
            prekeys.append(prekeyParam)
        }

        let lastResortKey: [String: Any] = [
            "keyId": Int(self.lastResortPreKey.id),
            "publicKey": ((self.lastResortPreKey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString(),
        ]
        let signedPreKey: [String: Any] = [
            "keyId": Int(self.signedPrekey.id),
            "publicKey": ((self.signedPrekey.keyPair.publicKey() as NSData).prependKeyType() as Data).base64EncodedString(),
            "signature": self.signedPrekey.signature.base64EncodedString(),
        ]

        let payload: [String: Any] = [
            "identityKey": self.identityKey,
            "lastResortKey": lastResortKey,
            "password": self.password,
            "preKeys": prekeys,
            "registrationId": Int(self.registrationId),
            "signalingKey": self.signalingKey,
            "signedPreKey": signedPreKey,
        ]

        return payload
    }()

    init(storageManager: TSStorageManager) {
        if storageManager.identityKeyPair() == nil {
            storageManager.generateNewIdentityKey()
        }

        self.identityKey = ((storageManager.identityKeyPair().publicKey() as NSData).prependKeyType() as Data).base64EncodedString()
        self.lastResortPreKey = storageManager.getOrGenerateLastResortKey()
        self.password = DeviceSpecificPassword
        self.prekeys = storageManager.generatePreKeyRecords() as! [PreKeyRecord]

        self.registrationId = TSAccountManager.getOrGenerateRegistrationId()

        self.signalingKey = CryptoTools.generateSecureRandomData(52).base64EncodedString()

        let keyPair = Curve25519.generateKeyPair()!
        let keyToSign = (keyPair.publicKey() as NSData).prependKeyType()! as Data
        let signature = Ed25519.sign(keyToSign, with: storageManager.identityKeyPair())! as Data

        let signedPK = SignedPreKeyRecord(id: Int32(0), keyPair: keyPair, signature: signature, generatedAt: Date())!

        self.signedPrekey = signedPK

        for prekey in self.prekeys {
            storageManager.storePreKey(prekey.id, preKeyRecord: prekey)
        }

        storageManager.storeSignedPreKey(self.signedPrekey.id, signedPreKeyRecord: self.signedPrekey)
    }
}
