import Foundation
import SweetFoundation
import Teapot

public class IDAPIClient: NSObject {
    static let shared: IDAPIClient = IDAPIClient(cereal: Cereal())

    public static let updateContactsNotification = Notification.Name(rawValue: "UpdateContactWithAddress")

    public static let didFetchContactInfoNotification = Notification.Name(rawValue: "DidFetchContactInfo")

    public var cereal: Cereal

    public var teapot: Teapot

    private var imageCache = NSCache<NSString, UIImage>()

    let contactUpdateQueue = DispatchQueue(label: "token.updateContactsQueue")

    let yap: Yap = Yap.sharedInstance

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: TokenIdServiceBaseURLPath)!
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
                    self.findContact(name: tokenContact.address) { _ in
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

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {
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

    public func registerUserIfNeeded(_ success: @escaping (() -> Void)) {
        self.retrieveUser(username: self.cereal.address) { user in
            guard user == nil else {
                User.current = user

                return
            }

            self.fetchTimestamp { timestamp in
                let path = "/v1/user"
                let parameters = [
                    "payment_address": self.cereal.paymentAddress,
                ]
                let parametersString = String(data: try! JSONSerialization.data(withJSONObject: parameters, options: []), encoding: .utf8)!
                let hashedParameters = self.cereal.sha3WithID(string: parametersString)
                let signature = "0x\(self.cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedParameters)"))"

                let fields: [String: String] = ["Token-ID-Address": self.cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

                let json = JSON(parameters)
                self.teapot.post(path, parameters: json, headerFields: fields) { result in
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

    public func updateUser(_ user: User, completion: @escaping ((_ success: Bool) -> Void)) {
        self.fetchTimestamp { timestamp in
            let path = "/v1/user"
            let payload = user.JSONData
            let payloadString = String(data: payload, encoding: .utf8)!

            let hashedPayload = self.cereal.sha3WithID(string: payloadString)
            let signature = "0x\(self.cereal.signWithID(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": self.cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = JSON(user.asDict)

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

    public func retrieveUser(username: String, completion: @escaping ((User?) -> Void)) {
        self.teapot.get("/v1/user/\(username)", headerFields: ["Token-Timestamp": String(Int(Date().timeIntervalSince1970))]) { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                // we know it's a dictionary for this API
                guard let json = json?.dictionary else { completion(nil); return }
                let user = User(json: json)

                print("Current user with address: \(user.address)")

                completion(user)
            case .failure(let json, let response, let error):
                print(error.localizedDescription)
                print(response)
                print(json?.dictionary ?? "")

                completion(nil)
            }
        }
    }

    func downloadAvatar(path: String, completion: @escaping (_ image: UIImage?) -> Void) {
        if let image = self.imageCache.object(forKey: path as NSString) {
            completion(image)

            return
        }

        self.teapot.get(path) { (result: NetworkImageResult) in
            switch result {
            case .success(let image, _):
                self.imageCache.setObject(image, forKey: path as NSString)
                completion(image)
            case .failure(let response, let error):
                print(response)
                print(error)
                completion(nil)
            }
        }
    }

    public func findContact(name: String, completion: @escaping ((TokenContact?) -> Void)) {
        self.teapot.get("/v1/user/\(name)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { completion(nil); return }

                let contact = TokenContact(json: json)
                NotificationCenter.default.post(name: IDAPIClient.didFetchContactInfoNotification, object: contact)

                completion(contact)
            case .failure(_, let response, let error):
                print(response)
                print(error.localizedDescription)
                completion(nil)
            }
        }
    }

    public func searchContacts(name: String, completion: @escaping (([TokenContact]) -> Void)) {
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
