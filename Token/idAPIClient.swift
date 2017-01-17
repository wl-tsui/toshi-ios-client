import Foundation
import SweetFoundation
import Networking

public class IDAPIClient: NSObject {
    // https://token-id-service.herokuapp.com/v1/user

    public var cereal: Cereal

    public var networking: Networking

    let yap: Yap = Yap.sharedInstance

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: "https://token-id-service.herokuapp.com")!
        self.networking = Networking(baseURL: self.baseURL.absoluteString)
    }

    public func registerUserIfNeeded() {
        self.retrieveUser(username: self.cereal.address) { user in
            guard user == nil else {
                User.current = user

                return
            }

            let parameters = UserIDRegistrationParameters(name: nil, username: nil, cereal: self.cereal)
            let signedParameters = parameters.signedParameters()

            self.networking.POST("/v1/user", parameterType: .json, parameters: signedParameters) { (json, error) in
                if let error = error {
                    print(error)
                } else if let json = json as? [String: Any] {
                    print("Registered user with address: \(self.cereal.address).")
                    User.current = User(json: json)
                } else {
                    fatalError()
                }
            }
        }
    }

    public func updateUser() {
        let parameters = UserIDRegistrationParameters(name: User.current?.name, username: User.current?.username, cereal: self.cereal, location: User.current?.location, about: User.current?.about)
        let signedParameters = parameters.signedParameters()
        print(signedParameters)
        self.networking.PUT("/v1/user", parameterType: .json, parameters: signedParameters) { json, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let json = json {
                print(json)
            } else {
                fatalError()
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

    public func findContact(name: String, completion: @escaping((TokenContact?) -> Void)) {
        self.networking.GET("/v1/user/\(name)") { json, error in
            if let error = error {
                print(error)
                completion(nil)
            } else if let json = json as? [String: Any] {
                let contact = TokenContact(json: json)
                if !self.yap.containsObject(for: contact.address, in: TokenContact.collectionKey) {
                    self.yap.insert(object: contact.JSONData, for: contact.address, in: TokenContact.collectionKey)
                }
                completion(contact)
            }
        }
    }

    public func searchContacts(name: String, completion: @escaping(([TokenContact]) -> Void)) {
        // /v1/search/user/?query=moxiemarl&offset=80&limit=20
        self.networking.GET("/v1/search/user/?query=\(name)") { json, error in
            if let error = error {
                print(error.localizedDescription)
                completion([])
            } else if let json = (json as? [String: Any])?["results"] as? [[String: Any]] {
                var contacts = [TokenContact]()
                for item in json {
                    contacts.append(TokenContact(json: item))
                }

                completion(contacts)
            }
        }
    }
}
