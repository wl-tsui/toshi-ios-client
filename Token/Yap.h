#import <Foundation/Foundation.h>

@interface Yap : NSObject

+ (nonnull instancetype)sharedYap;

/// Insert a object into the database using the main thread default connection.
///
/// - Parameters:
///   - object: Object to be stored. Must be serialisable. If nil, delete the record from the database.
///   - key: Key to store and retrieve object.
///   - collection: Optional. The name of the collection the object belongs to. Helps with organisation.
///   - metadata: Optional. Any serialisable object. Could be a related object, a description, a timestamp, a dictionary, and so on.
- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key NS_SWIFT_NAME(insert(_:for:));
- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection NS_SWIFT_NAME(insert(_:for:in:));
- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection withMetadata:(nullable NSString *)metadata NS_SWIFT_NAME(insert(_:for:in:with:));

/// Checks whether an object was stored for a given key inside a given (optional) collection.
///
/// - Parameter key: Key to check for the presence of a stored object.
/// - Returns: Bool whether or not a certain object was stored for that key.
- (BOOL)containsObjectForKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection NS_SWIFT_NAME(contains(for:in:));
- (BOOL)containsObjectForKey:(nonnull NSString *)key NS_SWIFT_NAME(contains(for:));

/// Retrieve an object for a given key inside a given (optional) collection.
///
/// - Parameters:
///   - key: Key used to store the object
///   - collection: Optional. The name of the collection the object was stored in.
/// - Returns: The stored object.
- (nullable id)retrieveObjectForKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection NS_SWIFT_NAME(retrieve(for:in:));
- (nullable id)retrieveObjectForKey:(nonnull NSString *)key NS_SWIFT_NAME(retrieve(for:));

@end
