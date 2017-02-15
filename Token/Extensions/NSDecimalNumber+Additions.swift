import Foundation

public extension NSDecimalNumber {

    public static var weiRoundingBehavior: NSDecimalNumberHandler {
        get {
            return NSDecimalNumberHandler(roundingMode: .up, scale: User.weisToEtherPowerOf10Constant, raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
        }
    }
    
    public var toDecimalString: String {
        return String(describing: self)
    }

    public var toHexString: String {
        return "0x\(BaseConverter.decToHex(self.toDecimalString).lowercased())"
    }

    public convenience init(hexadecimalString hexString: String) {
        var hexString = hexString.replacingOccurrences(of: "0x", with: "")

        // First we perform some sanity checks on the string. Then we chop it in 8 pieces and convert each to a UInt32.
        assert(hexString.characters.count > 0, "Can't be empty")

        // Assert if string isn't too long
        assert(hexString.characters.count <= 64, "Too large")

        hexString = hexString.uppercased()

        // Assert if string has any characters that are not 0-9 or A-F
        for character in hexString.characters {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F":
                assert(true)
            default:
                assert(false, "Invalid character")
            }
        }

        // Pad zeros
        if hexString.characters.count < 64 {
            for _ in 1 ... (64 - hexString.characters.count) {
                hexString = "0" + hexString
            }
        }

        let decimal = BaseConverter.hexToDec(hexString)

        self.init(string: decimal)
    }
}
