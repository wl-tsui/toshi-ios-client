import Foundation
import EtherealCereal

public class Cereal: NSObject {
    var cereal: EtherealCereal

    let yap = Yap.shared()

    public var address: String {
        return self.cereal.address
    }

    public override init() {
//        if let privateKey = self.yap.retrieve(for: "cerealPrivateKey") as? String {
        let device = "2d3a08007570fccf8ba8cda3dc1ef41c59af94617b585bfff60b711a1a4e471b"
        let sim = "9f1c04eb451c0ad6af495244cf2ffd538e6b8df9f34c74f078423254c0062fb7"
        self.cereal = EtherealCereal(privateKey: device)
//        } else {
//            self.cereal = EtherealCereal()
//            self.yap.insert(cereal.privateKey, for: "cerealPrivateKey")
//        }
    }

    public func sign(message: String) -> String {
        return self.cereal.sign(message: message)
    }
}
