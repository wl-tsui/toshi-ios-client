import Foundation
import SweetFoundation
import Networking

public class IDAPIClient: NSObject {
    // https://token-id-service.herokuapp.com/v1/user

    public var cereal: Cereal

    public var networking: Networking

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: "https://token-id-service.herokuapp.com")!
        self.networking = Networking(baseURL: self.baseURL.absoluteString)
    }

    public func registerUserIfNeeded(username: String? = nil, name: String? = nil) {
        self.retrieveUser(username: username ?? self.cereal.address) { user in
            guard user == nil else {
                User.current = user

                return
            }

            let userParameters = UserIDRegistrationParameters(name: name, username: username, cereal: self.cereal)
            self.networking.POST("/v1/user", parameterType: .json, parameters: userParameters.signedParameters()) { (json, error) in
                if let error = error {
                    print(error)
                } else if let json = json as? [String: Any] {
                    User.current = User(json: json)
                } else {
                    fatalError()
                }
            }
        }
    }

    public func retrieveUser(username: String, completion: @escaping((User?) -> Void)) {
        self.networking.GET("/v1/user/\(username)/") { json, error in
            if let error = error {
                print(error)
                completion(nil)
            } else if let json = json as? [String: Any] {
                completion(User(json: json))
            }
        }
    }
}
