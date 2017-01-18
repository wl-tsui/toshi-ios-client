import Foundation
import Networking

public protocol TimestampSynchronizing {
    var networking: Networking { get set }

    func fetchTimestamp(_ completion: @escaping((Int) -> Void))
}

public extension TimestampSynchronizing {
    public func fetchTimestamp(_ completion: @escaping((Int) -> Void)) {
        self.networking.GET("/v1/timestamp") { json, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let json = json as? [String: Any] {
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Time stamp was not an integer?!") }
                completion(timestamp)
            } else {
                fatalError()
            }
        }
    }
}
