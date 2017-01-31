import Foundation
import Teapot
import UInt256

class EthereumAPIClient {
    static let shared: EthereumAPIClient = EthereumAPIClient()

    public var teapot: Teapot

    init() {
        self.teapot = Teapot(baseURL: URL(string: "https://token-eth-service.herokuapp.com")!)
    }

    func getBalance(address: String, completion: @escaping(_ balance: UInt256, _ error: Error?) -> Void) {
        self.teapot.get("/v1/balance/\(address)") { result in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError() }
                guard let json = json?.dictionary else { fatalError() }

                // TODO: use real balance instead
                let confirmedBalanceString = json["confirmed_balance"] as? String ?? "0"
                if confirmedBalanceString == "0x0" {
                    completion(UInt256(hexString: "3210000000000000000"), nil)
                } else {
                    completion(UInt256(hexString: confirmedBalanceString), nil)
                }
            case .failure(let json, let response, let error):
                completion(0, error)
                print(error)
                print(response)
                print(json ?? "")
            }
        }
    }
}
