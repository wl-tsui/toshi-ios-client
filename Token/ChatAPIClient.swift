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
        return TSStorageManager.shared()
    }()

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: "https://token-chat-service.herokuapp.com")!
        self.teapot = Teapot(baseURL: self.baseURL)
    }

    public func registerUserIfNeeded() {
        let parameters = UserBootstrapParameter(storageManager: self.storageManager, timestamp: Int(Date().timeIntervalSince1970), ethereumAddress: self.address)

        let message = parameters.stringForSigning()
        let signature = self.cereal.sign(message: message)
        parameters.signature = "0x\(signature)"

        guard let signedParameters = parameters.signedParametersDictionary() else { fatalError("Missing signature!") }
        let json = JSON(signedParameters)

        self.teapot.put("/v1/accounts/bootstrap/", parameters: json) { result in
            switch result {
            case .success(_, let response):
                guard response.statusCode == 204 else {
                    print("Could not register user. Status code \(response.statusCode)")

                    return
                }

                TSStorageManager.storeServerToken(DeviceSpecificPassword, signalingKey: parameters.signalingKey)

//                let auth = self.authToken(for: self.address, password: DeviceSpecificPassword)
//                self.networking.setAuthorizationHeader(headerValue: auth)

                print("Successfully registered chat user with address: \(self.cereal.address)")
            case .failure(let json, let response, let error):
                print(json ?? "")
                print(response)
                print(error)
            }
        }
    }

    func authToken(for address: String, password: String) -> String {
        return "Basic \("\(address):\(password)".data(using: .utf8)!.base64EncodedString())"
    }
}
