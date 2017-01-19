import Foundation
import Networking

class EthereumAPIClient {
    static let shared: EthereumAPIClient = EthereumAPIClient()

    public var networking: Networking

    init() {
        self.networking = Networking(baseURL: "https://token-eth-service.herokuapp.com")
    }

    func getBalance(address: String, completion: @escaping (_ balance: Double, _ error: NSError?) -> Void) {
        self.networking.fakeGET("/v1/balance/\(address)", response: ["confirmed_balance": 3000000000000000000])
        self.networking.GET("/v1/balance/\(address)") { json, error in
            if let error = error {
                completion(0, error)
            } else {
                let json = json as? [String: Any] ?? [String: Any]()
                let confirmedBalance = json["confirmed_balance"] as? Double ?? 0
                completion(confirmedBalance, nil)
            }
        }
    }
}
