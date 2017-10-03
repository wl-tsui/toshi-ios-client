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
import EtherealCereal
import HDWallet

/// An EtherealCereal wrapper. Generates the address and public key for a given private key. Signs messages.
public class Cereal: NSObject {

    @objc public static var shared: Cereal = Cereal()

    let entropyByteCount = 16

    var idCereal: EtherealCereal?

    var walletCereal: EtherealCereal?

    var mnemonic: BTCMnemonic?

    static let privateKeyStorageKey = "cerealPrivateKey"

    @objc public var address: String? {
        return idCereal?.address
    }

    public var paymentAddress: String? {
        return walletCereal?.address
    }

    @objc func prepareForLoggedInUser() {
        if let words = Yap.sharedInstance.retrieveObject(for: Cereal.privateKeyStorageKey) as? String {
            guard let mnemonicValue = BTCMnemonic(words: words.components(separatedBy: " "), password: nil, wordListType: .english) else { fatalError("Entropy has incorrect size or wordlist is not supported") }
            mnemonic = mnemonicValue

            setup(for: words.components(separatedBy: " "))
        }
    }

    @objc func setupForNewUser() {
        var entropy = Data(count: entropyByteCount)
        // This creates the private key inside a block, result is of internal type ResultType.
        // We just need to check if it's 0 to ensure that there were no errors.
        let result = entropy.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, entropy.count, mutableBytes)
        }

        guard result == 0 else { fatalError("Failed to randomly generate and copy bytes for entropy generation. SecRandomCopyBytes error code: (\(result)).") }
        guard let mnemonic = BTCMnemonic(entropy: entropy, password: nil, wordListType: .english) else { fatalError("Entropy has incorrect size or wordlist is not supported") }

        Yap.sharedInstance.insert(object: mnemonic.words.joined(separator: " "), for: Cereal.privateKeyStorageKey)

        setup(for: mnemonic.words)
    }

    @objc func save() {
        Yap.sharedInstance.insert(object: mnemonic!.words.joined(separator: " "), for: Cereal.privateKeyStorageKey)
    }

    @objc @discardableResult func setup(for words: [String]) -> Bool {
        guard let mnemonic = BTCMnemonic(words: words, password: nil, wordListType: .english) else {
            print("Impossible to initialize mnemonic for given words")
            return false
        }
        self.mnemonic = mnemonic

        Yap.sharedInstance.insert(object: mnemonic.words.joined(separator: " "), for: Cereal.privateKeyStorageKey)

        // ID path 0H/1/0
        let idKeychain = mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 1).derivedKeychain(at: 0)
        let idPrivateKey = idKeychain.key.privateKey.hexadecimalString()
        idCereal = EtherealCereal(privateKey: idPrivateKey)

        // wallet path: 44H/60H/0H/0
        let walletKeychain = mnemonic.keychain.derivedKeychain(at: 44, hardened: true).derivedKeychain(at: 60, hardened: true).derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 0).derivedKeychain(at: 0)
        let walletPrivateKey = walletKeychain.key.privateKey.hexadecimalString()
        walletCereal = EtherealCereal(privateKey: walletPrivateKey)

        return true
    }

    @objc public func endSession() {
        self.idCereal = nil
        self.walletCereal = nil
    }

    // MARK: - Sign with id

    public func signWithID(message: String) -> String {
        guard let cereal = idCereal as EtherealCereal? else { fatalError("No idCereal when requested") }
        return cereal.sign(message: message)
    }

    public func signWithID(hex: String) -> String {
        guard let cereal = idCereal as EtherealCereal? else { fatalError("No idCereal when requested") }
        return cereal.sign(hex: hex)
    }

    public func sha3WithID(string: String) -> String {
        guard let cereal = idCereal as EtherealCereal? else { fatalError("No idCereal when requested") }
        return cereal.sha3(string: string)
    }

    public func sha3WithID(data: Data) -> String {
        guard let cereal = idCereal as EtherealCereal? else { fatalError("No idCereal when requested") }
        return cereal.sha3(data: data)
    }

    // MARK: - Sign with wallet

    public func signWithWallet(message: String) -> String {
        guard let walletCereal = self.walletCereal as EtherealCereal?  else { fatalError ("No wallet cereal when requested") }
        return walletCereal.sign(message: message)
    }

    public func signWithWallet(hex: String) -> String {
        guard let walletCereal = self.walletCereal as EtherealCereal?  else { fatalError("No wallet cereal when requested") }
        return walletCereal.sign(hex: hex)
    }

    public func sha3WithWallet(string: String) -> String {
        guard let walletCereal = self.walletCereal as EtherealCereal?  else { fatalError("No wallet cereal when requested") }
        return walletCereal.sha3(string: string)
    }
}
