// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

@testable import Toshi
import XCTest

class StringAdditionsTests: XCTestCase {
    
    func testEnteringAValidPrefixDoesntCreateAPossibleURL() {
        XCTAssertNil("h".asPossibleURLString)
        XCTAssertNil("ht".asPossibleURLString)
        XCTAssertNil("htt".asPossibleURLString)
        XCTAssertNil("http".asPossibleURLString)
        
        XCTAssertNil("http:".asPossibleURLString)
        XCTAssertNil("http:/".asPossibleURLString)
        XCTAssertNil("http://".asPossibleURLString)
        XCTAssertEqual("http://a".asPossibleURLString, "http://a")

        XCTAssertNil("https".asPossibleURLString)
        XCTAssertNil("https:".asPossibleURLString)
        XCTAssertNil("https:/".asPossibleURLString)
        XCTAssertNil("https://".asPossibleURLString)
        XCTAssertEqual("https://a".asPossibleURLString, "https://a")

        XCTAssertNil("f".asPossibleURLString)
        XCTAssertNil("ft".asPossibleURLString)
        XCTAssertNil("ftp".asPossibleURLString)
        XCTAssertNil("ftp:".asPossibleURLString)
        XCTAssertNil("ftp:/".asPossibleURLString)
        XCTAssertNil("ftp://".asPossibleURLString)
        XCTAssertEqual("ftp://a".asPossibleURLString, "ftp://a")
        
        XCTAssertNil("fo".asPossibleURLString)
        XCTAssertNil("foo".asPossibleURLString)
        XCTAssertNil("foo:".asPossibleURLString)
        XCTAssertNil("foo:/".asPossibleURLString)
        XCTAssertNil("foo://".asPossibleURLString)
        XCTAssertEqual("foo://a".asPossibleURLString, "foo://a")
    }
    
    func testAddingSomethingWithADotAndOneExtraCharacterCreatesPossibleURLString() {
        XCTAssertNil("foo".asPossibleURLString)
        XCTAssertNil("foo.".asPossibleURLString)
        XCTAssertEqual("foo.b".asPossibleURLString, "http://foo.b")
    }
    
    func testCaseCorrectionInPossibleURLStrings() {
        XCTAssertEqual("foo.bar".asPossibleURLString, "http://foo.bar")
        XCTAssertEqual("Foo.bar".asPossibleURLString, "http://foo.bar")
        XCTAssertEqual("FOO.BAR".asPossibleURLString, "http://foo.bar")
    }
    
    func testDescribesValueLargerThanZero() {
        XCTAssertTrue("1.00".isValidPaymentValue())
        XCTAssertTrue("1,00".isValidPaymentValue())
        XCTAssertTrue("0.10".isValidPaymentValue())
        XCTAssertTrue("0,10".isValidPaymentValue())
        XCTAssertFalse("0.00".isValidPaymentValue())
        XCTAssertFalse("0,00".isValidPaymentValue())
        XCTAssertFalse("-1.00".isValidPaymentValue())
        XCTAssertFalse("-1,00".isValidPaymentValue())
        XCTAssertFalse("hi".isValidPaymentValue())
    }

    func testSplittingStringIntoLines() {
        let shortString = "foo"

        let splitShort = shortString.toLines(count: 3)

        XCTAssertEqual(splitShort, """
f
o
o
""")

        let mediumString = "HelloThereEllen"
        let evenSplitMedium = mediumString.toLines(count: 3)
        XCTAssertEqual(evenSplitMedium, """
Hello
There
Ellen
""")
        let unevenSplitMedium = mediumString.toLines(count: 2)
        XCTAssertEqual(unevenSplitMedium, """
HelloThe
reEllen
""")
        let unevenerSplitMedium = mediumString.toLines(count: 4)
        XCTAssertEqual(unevenerSplitMedium, """
Hell
oThe
reEl
len
""")
        let unevenSupersplitMedium = mediumString.toLines(count: 7)
        XCTAssertEqual(unevenSupersplitMedium, """
He
ll
oT
he
re
El
len
""")

    }

    func testToChecksumEncodedAddress() {
        XCTAssertEqual("0x52908400098527886e0f7030069857d2e4169ee7".toChecksumEncodedAddress(), "0x52908400098527886E0F7030069857D2E4169EE7")
        XCTAssertEqual("0x8617e340b3d01fa5f11f306f4090fd50e238070d".toChecksumEncodedAddress(), "0x8617E340B3D01FA5F11F306F4090FD50E238070D")
        XCTAssertEqual("0xdE709F2102306220921060314715629080e2Fb77".toChecksumEncodedAddress(), "0xde709f2102306220921060314715629080e2fb77")
        XCTAssertEqual("0x27b1fdb04752bbc536007a920d24acb045561c26".toChecksumEncodedAddress(), "0x27b1fdb04752bbc536007a920d24acb045561c26")
        XCTAssertEqual("0x5aaeb6053f3e94c9b9a09f33669435e7ef1Beaed".toChecksumEncodedAddress(), "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")
        XCTAssertEqual("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359".toChecksumEncodedAddress(), "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
        XCTAssertEqual("0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb".toChecksumEncodedAddress(), "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB")
        XCTAssertEqual("0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb".toChecksumEncodedAddress(), "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb")
        XCTAssertNil("Abcd".toChecksumEncodedAddress())
    }

    func testToDisplayValueWithTokens() {
        var decimals: Int = 18
        var inputValue = "0x1fbc58a15fb36dfb9"

        XCTAssertEqual(inputValue.toDisplayValue(with: decimals), "36.588802574655086521")

        inputValue = "0x3a81a92faf"
        decimals = 10
        XCTAssertEqual(inputValue.toDisplayValue(with: decimals), "25.1283451823")

        decimals = 30
        XCTAssertEqual(inputValue.toDisplayValue(with: decimals), "0.000000000000000000251283451823")

        decimals = 0
        XCTAssertEqual(inputValue.toDisplayValue(with: decimals), "251283451823")
    }
}
