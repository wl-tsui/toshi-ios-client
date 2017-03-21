import UIKit
import Teapot
import SweetFoundation

public class ChatAPIClient: NSObject {

    public var cereal: Cereal

    public var teapot: Teapot

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public lazy var storageManager: TSStorageManager = {
        TSStorageManager.shared()
    }()

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: TokenChatServiceBaseURLPath)!
        self.teapot = Teapot(baseURL: self.baseURL)
    }

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {
        self.teapot.get("/v1/accounts/bootstrap/") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError("Could not retrieve timestamp from chat service.") }
                guard let json = json?.dictionary else { fatalError("JSON dictionary not found in payload") }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp not found in json payload or not an integer.") }

                completion(timestamp)
            case .failure(let json, let response, let error):
                print(error)
                print(response)
                print(json ?? "")
            }
        }
    }

    public func registerUserIfNeeded() {
        self.fetchTimestamp { timestamp in
            let parameters = UserBootstrapParameter(storageManager: self.storageManager)
            let path = "/v1/accounts/bootstrap"
            let payload = parameters.payload
            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3WithID(string: payloadString)
            let message = "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(self.cereal.signWithID(message: message))"

            let fields: [String: String] = ["Token-ID-Address": self.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = JSON(payload)

            self.teapot.put(path, parameters: json, headerFields: fields) { result in
                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        print("Could not register user. Status code \(response.statusCode)")

                        return
                    }

                    TSStorageManager.storeServerToken(DeviceSpecificPassword, signalingKey: parameters.signalingKey)
                    print("Successfully registered chat user with address: \(self.cereal.address)")
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }

    func authToken(for address: String, password: String) -> String {
        return "Basic \("\(address):\(password)".data(using: .utf8)!.base64EncodedString())"
    }
}
