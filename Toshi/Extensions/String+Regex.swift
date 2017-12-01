import Foundation

extension String {

    public var hasAddressPrefix: Bool {
        return starts(with: "0x")
    }

    public func firstMatch(pattern: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.length))
    }
}
