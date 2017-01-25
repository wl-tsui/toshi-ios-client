import Foundation
import Networking
import UInt256

class EthereumAPIClient {
    static let shared: EthereumAPIClient = EthereumAPIClient()

    public var networking: Networking

    init() {
        self.networking = Networking(baseURL: "https://token-eth-service.herokuapp.com")
    }

    func getBalance(address: String, completion: @escaping(_ balance: UInt256, _ error: NSError?) -> Void) {
        self.networking.fakeGET("/v1/balance/\(address)", response: ["confirmed_balance": "3210000000000000000"])
        self.networking.GET("/v1/balance/\(address)") { json, error in
            if let error = error {
                completion(0, error)
            } else {
                let json = json as? [String: Any] ?? [String: Any]()
                let confirmedBalanceString = json["confirmed_balance"] as? String ?? "0"
                let balance = UInt256(hexString: confirmedBalanceString)
                completion(balance, nil)
            }
        }
    }
}
