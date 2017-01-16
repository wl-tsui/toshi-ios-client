import Foundation
import EtherealCereal

public class Cereal: NSObject {
    var cereal: EtherealCereal

    let yap = Yap.sharedInstance

    private static let collectionKey = "cerealPrivateKey"

    public var address: String {
        return self.cereal.address
    }

    public override init() {
        if let privateKey = self.yap.retrieveObject(for: Cereal.collectionKey) as? String {
            self.cereal = EtherealCereal(privateKey: privateKey)
        } else {
            self.cereal = EtherealCereal()
            self.yap.insert(object: cereal.privateKey, for: Cereal.collectionKey)
        }
    }

    public func sign(message: String) -> String {
        return self.cereal.sign(message: message)
    }
}
