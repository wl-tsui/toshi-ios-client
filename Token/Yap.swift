import Foundation
import YapDatabase

protocol Singleton: class {
    static var sharedInstance: Self { get }
}

public final class Yap: Singleton {
    var database: YapDatabase

    public var mainConnection: YapDatabaseConnection

    public static let sharedInstance = Yap()

    private init() {
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(".Signal.sqlite").path else { fatalError("Missing resource path!") }

        let options = YapDatabaseOptions()
        options.corruptAction = .fail
        self.database = YapDatabase(path: path, options: options)

        self.mainConnection = self.database.newConnection()
    }

    /// Insert a object into the database using the main thread default connection.
    ///
    /// - Parameters:
    ///   - object: Object to be stored. Must be serialisable. If nil, delete the record from the database.
    ///   - key: Key to store and retrieve object.
    ///   - collection: Optional. The name of the collection the object belongs to. Helps with organisation.
    ///   - metadata: Optional. Any serialisable object. Could be a related object, a description, a timestamp, a dictionary, and so on.
    public final func insert(object: Any?, for key: String, in collection: String? = nil, with metadata: Any? = nil) {
        self.mainConnection.readWrite { (transaction) in
            transaction.setObject(object, forKey: key, inCollection: collection, withMetadata: metadata)
        }
    }

    /// Checks whether an object was stored for a given key inside a given (optional) collection.
    ///
    /// - Parameter key: Key to check for the presence of a stored object.
    /// - Returns: Bool whether or not a certain object was stored for that key.
    public final func containsObject(for key: String, in collection: String? = nil) -> Bool {
        return self.retrieveObject(for: key, in: collection) != nil
    }

    /// Retrieve an object for a given key inside a given (optional) collection.
    ///
    /// - Parameters:
    ///   - key: Key used to store the object
    ///   - collection: Optional. The name of the collection the object was stored in.
    /// - Returns: The stored object.
    public final func retrieveObject(for key: String, in collection: String? = nil) -> Any? {
        var object: Any? = nil
        self.mainConnection.read { (transaction) in
            object = transaction.object(forKey: key, inCollection: collection)
        }

        return object
    }
}
