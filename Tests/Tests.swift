import XCTest
import SweetSwift

class Tests: XCTestCase {
    func testExample() {
        let balance = EthereumConverter.balanceAttributedString(forWei: NSDecimalNumber.zero, exchangeRate: 0.0005)
        print(balance)
        XCTAssertTrue(true)
    }
}
