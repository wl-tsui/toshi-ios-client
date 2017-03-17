import Foundation
import EtherealCereal
import HDWallet

/// An EtherealCereal wrapper. Generates the address and public key for a given private key. Signs messages.
public class Cereal: NSObject {

    let entropyByteCount = 16

    var idCereal: EtherealCereal

    var walletCereal: EtherealCereal

    var mnemonic: BTCMnemonic

    let yap = Yap.sharedInstance

    private static let collectionKey = "cerealPrivateKey"

    public var address: String {
        return self.idCereal.address
    }

    public var paymentAddress: String {
        return self.walletCereal.address
    }

    public override init() {
        if let words = self.yap.retrieveObject(for: Cereal.collectionKey) as? String {
            self.mnemonic = BTCMnemonic(words: words.components(separatedBy: " "), password: nil, wordListType: .english)!
        } else {
            var entropy = Data(count: self.entropyByteCount)
            // This creates the private key inside a block, result is of internal type ResultType.
            // We just need to check if it's 0 to ensure that there were no errors.
            let result = entropy.withUnsafeMutableBytes { mutableBytes in
                SecRandomCopyBytes(kSecRandomDefault, entropy.count, mutableBytes)
            }
            guard result == 0 else { fatalError("Failed to randomly generate and copy bytes for entropy generation. SecRandomCopyBytes error code: (\(result)).") }

            self.mnemonic = BTCMnemonic(entropy: entropy, password: nil, wordListType: .english)!

            self.yap.insert(object: self.mnemonic.words.joined(separator: " "), for: Cereal.collectionKey)
        }

        // ID path 0H/1/0
        let idKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 1).derivedKeychain(at: 0)
        let idPrivateKey = idKeychain.key.privateKey.hexadecimalString()
        self.idCereal = EtherealCereal(privateKey: idPrivateKey)

        // wallet path: 0H/0/0
        let walletKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 0).derivedKeychain(at: 0)
        let walletPrivateKey = walletKeychain.key.privateKey.hexadecimalString()
        self.walletCereal = EtherealCereal(privateKey: walletPrivateKey)
    }

    // MARK: - Sign with id

    public func signWithID(message: String) -> String {
        return self.idCereal.sign(message: message)
    }

    public func signWithID(hex: String) -> String {
        return self.idCereal.sign(hex: hex)
    }

    public func sha3WithID(string: String) -> String {
        return self.idCereal.sha3(string: string)
    }

    // MARK: - Sign with wallet

    public func signWithWallet(message: String) -> String {
        return self.walletCereal.sign(message: message)
    }

    public func signWithWallet(hex: String) -> String {
        return self.walletCereal.sign(hex: hex)
    }

    public func sha3WithWallet(string: String) -> String {
        return self.walletCereal.sha3(string: string)
    }
}
