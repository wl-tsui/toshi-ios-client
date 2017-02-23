import Foundation
import Teapot

public class EthereumAPIClient: NSObject {

    static let shared: EthereumAPIClient = EthereumAPIClient()

    private static let collectionKey = "ethereumExchangeRate"

    public var teapot: Teapot

    private var exchangeTeapot: Teapot

    public var cereal = Cereal()

    let yap = Yap.sharedInstance

    public var exchangeRate: Decimal {
        get {
            self.updateRate()

            if let rate = self.yap.retrieveObject(for: EthereumAPIClient.collectionKey) as? Decimal {
                EthereumConverter.latestExchangeRate = rate
            } else {
                EthereumConverter.latestExchangeRate = 10.0
            }

            return EthereumConverter.latestExchangeRate
        }
    }

    private override init() {
        self.teapot = Teapot(baseURL: URL(string: TokenEthereumServiceBaseURLPath)!)
        self.exchangeTeapot = Teapot(baseURL: URL(string: "https://api.coinbase.com")!)

        super.init()

        self.updateRate()
    }

    private func updateRate() {
        self.getRate { (rate) in
            self.yap.insert(object: rate, for: EthereumAPIClient.collectionKey)
        }
    }

    func timestamp(_ completion: @escaping((_ timestamp: String) -> Void)) {
        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(String(timestamp))
            case .failure(_, _, let error):
                print(error)
            }
        }
    }

    func getRate(_ completion: @escaping((_ rate: Decimal) -> Void)) {
        //
        self.exchangeTeapot.get("/v2/exchange-rates?currency=ETH") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError() }
                guard let data = json["data"] as? [String: Any] else { fatalError() }
                guard let rates = data["rates"] as? [String: Any] else { fatalError() }
                guard let usd = rates["USD"] as? String else { fatalError() }

                completion(Decimal(Double(usd)!))
            case .failure(_, let response, let error):
                print(response)
                fatalError(error.localizedDescription)
            }
        }
    }

    public func createUnsignedTransaction(to address: String, value: NSDecimalNumber, completion: @escaping((_ unsignedTransaction: String?, _ error: Error?) -> Void)) {
        let parameters: [String: Any] = [
            "from": self.cereal.paymentAddress,
            "to": address,
            "value": value.toHexString,
        ]

        let json = JSON(parameters)

        self.teapot.post("/v1/tx/skel", parameters: json) { result in
            switch result {
            case .success(let json, let response):
                print(response)
                completion(json!.dictionary!["tx"] as? String, nil)
            case .failure(let json, let response, let error):
                print(response)
                print(json ?? "")
                print(error)
                completion(nil, error)
            }
        }
    }

    public func sendSignedTransaction(originalTransaction: String, transactionSignature: String, completion: @escaping((_ json: JSON?, _ error: Error?) -> Void)) {
        self.timestamp { (timestamp) in

            let path = "/v1/tx"

            let params = [
                "tx": originalTransaction,
                "signature": transactionSignature,
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3WithWallet(string: payloadString)

            let signature = "0x\(self.cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headers: [String: String] = [
                "Token-ID-Address": self.cereal.paymentAddress,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = JSON(params)

            self.teapot.post(path, parameters: json, headerFields: headers) { (result) in
                switch result {
                case .success(let json, let response):
                    print(response)
                    print(json ?? "")
                    completion(json, nil)
                case .failure(let json, let response, let error):
                    print(response)
                    print(json ?? "")
                    print(error)
                    let json = JSON((json!.dictionary!["errors"] as! [[String: Any]]).first!)
                    completion(json, error)
                }
            }
        }
    }

    public func getBalance(address: String, completion: @escaping((_ balance: NSDecimalNumber, _ error: Error?) -> Void)) {
        self.teapot.get("/v1/balance/\(address)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError() }
                guard let json = json?.dictionary else { fatalError() }

                let confirmedBalanceString = json["confirmed_balance"] as? String ?? "0"

                completion(NSDecimalNumber(hexadecimalString: confirmedBalanceString), nil)
            case .failure(let json, let response, let error):
                completion(0, error)
                print(error)
                print(response)
                print(json ?? "")
            }
        }
    }

    public func registerForPushNotifications(deviceToken: String) {
        self.timestamp { (timestamp) in
            let path = "/v1/apn/register"
            let address = self.cereal.paymentAddress

            let params = ["registration_id": deviceToken]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(self.cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = JSON(params)
            self.teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }

    public func registerForNotifications(_ completion: @escaping((_ success: Bool) -> Void)) {
        self.timestamp { (timestamp) in
            let address = User.current!.paymentAddress
            let path = "/v1/register"

            let params = [
                "addresses": [
                    address,
                ],
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(self.cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = JSON(params)

            self.teapot.post(path, parameters: json, headerFields: headerFields) { (result) in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                    completion(true)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                    completion(false)
                }
            }
        }
    }

    public func deregisterForNotifications() {
        self.timestamp { (timestamp) in
            let address = self.cereal.paymentAddress
            let path = "/v1/deregister"

            let params = [
                "addresses": [
                    address,
                ],
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(self.cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = JSON(params)

            self.teapot.post(path, parameters: json, headerFields: headerFields) { (result) in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }
}
