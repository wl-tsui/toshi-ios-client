import Foundation
import SweetFoundation
import Teapot

public class IDAPIClient: NSObject {
    // https://token-id-service.herokuapp.com

    public static let updateContactsNotification = Notification.Name(rawValue: "UpdateContactWithAddress")

    public static let didFetchContactInfoNotification = Notification.Name(rawValue: "DidFetchContactInfo")

    public var cereal: Cereal

    public var teapot: Teapot

    let contactUpdateQueue = DispatchQueue(label: "token.updateContactsQueue")

    let yap: Yap = Yap.sharedInstance

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: "https://token-id-service.herokuapp.com")!
        self.teapot = Teapot(baseURL: self.baseURL)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(IDAPIClient.updateContacts), name: IDAPIClient.updateContactsNotification, object: nil)
    }

    /// We use a background queue and a semaphore to ensure we only update the UI
    /// once all the contacts have been processed.
    func updateContacts() {
        self.contactUpdateQueue.async {
            guard let contactsData = self.yap.retrieveObjects(in: TokenContact.collectionKey) as? [Data] else { fatalError() }
            let semaphore = DispatchSemaphore(value: 0)

            for contactData in contactsData {
                guard let dictionary = try? JSONSerialization.jsonObject(with: contactData, options: []) else { continue }

                if let dictionary = dictionary as? [String: Any] {
                    let tokenContact = TokenContact(json: dictionary)
                    self.findContact(name: tokenContact.address) { contact in
                        semaphore.signal()
                    }
                    // calls to `wait()` need to be balanced with calls to `signal()`
                    // remember to call it _after_ the code we need to run asynchronously.
                    _ = semaphore.wait(timeout: .distantFuture)
                }
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: TokenContact.didUpdateContactInfoNotification, object: self)
            }
        }
    }

    func fetchTimestamp(_ completion: @escaping((Int) -> Void)) {
        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(timestamp)
            case .failure(_, let response, _):
                print(response)
                fatalError()
            }
        }
    }

    public func registerUserIfNeeded(_ success: @escaping((Void) -> Void)) {
        self.retrieveUser(username: self.cereal.address) { user in
            guard user == nil else {
                User.current = user

                return
            }

            self.fetchTimestamp { timestamp in
                let path = "/v1/user"
                let signature = "0x\(self.cereal.sign(message: "POST\n\(path)\n\(timestamp)\n"))"

                let fields: [String: String] = ["Token-ID-Address": self.cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

                self.teapot.post(path, headerFields: fields) { result in
                    switch result {
                    case .success(let json, let response):
                        guard response.statusCode == 200 else { return }
                        guard let json = json?.dictionary else { return }

                        User.current = User(json: json)
                        print("Registered user with address: \(self.cereal.address)")

                        success()
                    case .failure(let json, let response, let error):
                        print(response)
                        print(error)
                        print(json ?? "")
                    }
                }
            }
        }
    }

    public func updateUser(_ user: User, completion: @escaping((_ success: Bool) -> Void)) {
        self.fetchTimestamp { timestamp in
            let path = "/v1/user"
            let payload = user.asRequestParameters()
            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8)!
            let hashedPayload = self.cereal.sha3(string: payloadString)
            let signature = "0x\(self.cereal.sign(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": self.cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = JSON(payload)

            self.teapot.put("/v1/user", parameters: json, headerFields: fields) { result in
                switch result {
                case .success(let json, let response):
                    guard response.statusCode == 200 else { fatalError() }
                    guard let json = json?.dictionary else { fatalError() }

                    let user = User(json: json)
                    User.current = user
                    completion(true)
                case .failure(let json, let response, let error):
                    print(error)
                    print(json ?? "")
                    print(response)
                    completion(false)
                }
            }
        }
    }

    public func retrieveUser(username: String, completion: @escaping((User?) -> Void)) {
        self.teapot.get("/v1/user/\(username)", headerFields: ["Token-Timestamp": String(Int(Date().timeIntervalSince1970))]) { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                // we know it's a dictionary for this API
                guard let json = json?.dictionary else { completion(nil); return }
                let user = User(json: json)

                print("Current user with address: \(user.address)")

                // EthereumAPIClient.shared.registerForPushNotifications()
                // EthereumAPIClient.shared.registerForNotifications()
                //
                //  DispatchQueue.main.asyncAfter(seconds: 10, execute: {
                //    EthereumAPIClient.shared.deregisterForNotifications()
                //  })

                completion(user)
            case .failure(let json, let response, let error):
                print(error.localizedDescription)
                print(response)
                print(json?.dictionary ?? "")

                completion(nil)
            }
        }
    }

    public func findContact(name: String, completion: @escaping((TokenContact?) -> Void)) {
        self.teapot.get("/v1/user/\(name)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { completion(nil); return }

                let contact = TokenContact(json: json)
                self.yap.insert(object: contact.JSONData, for: contact.address, in: TokenContact.collectionKey)
                NotificationCenter.default.post(name: IDAPIClient.didFetchContactInfoNotification, object: contact)

                completion(contact)
            case .failure(_, let response, let error):
                print(response)
                print(error.localizedDescription)
                completion(nil)
            }
        }
    }

    public func searchContacts(name: String, completion: @escaping(([TokenContact]) -> Void)) {
        // /v1/search/user/?query=moxiemarl&offset=80&limit=20
        self.teapot.get("/v1/search/user?query=\(name)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)

                guard let dictionary = json?.dictionary, let json = dictionary["results"] as? [[String: Any]] else { completion([]); return }

                var contacts = [TokenContact]()
                for item in json {
                    contacts.append(TokenContact(json: item))
                }
                completion(contacts)
            case .failure(_, let response, let error):
                print(response)
                print(error.localizedDescription)
                completion([])
            }
        }
    }
}
