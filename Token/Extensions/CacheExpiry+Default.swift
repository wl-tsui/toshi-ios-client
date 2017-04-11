import AwesomeCache

protocol CacheExpiryDefault {
    var cacheExpiry: CacheExpiry { get }
}

extension CacheExpiryDefault {
    var cacheExpiry: CacheExpiry {
        return CacheExpiry.seconds(300)
    }
}
