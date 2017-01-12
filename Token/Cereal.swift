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
        let device = "27e50eb313b9c676985ae1639244ae34c61bf3536ca89a7136559ed6243efa5f"
        let sim = "781bcf75aef799c1c4a502707895a78c7fdaf2d17015cf3f8cfc790cccd372df"
        self.cereal = EtherealCereal(privateKey: sim)
//        } else {
//            self.cereal = EtherealCereal()
//            self.yap.insert(cereal.privateKey, for: "cerealPrivateKey")
//        }
    }

    public func sign(message: String) -> String {
        return self.cereal.sign(message: message)
    }
}
