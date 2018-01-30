//
//  AddressTests.swift
//  CPlaygroundTests
//
//  Created by Ellen Shapiro (Work) on 1/30/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import XCTest

class AddressTests: XCTestCase {

    func testCreatingAddress() {
        let stringAddress = "Hello!"
        let address = SignalWrapper.address(from: stringAddress)
        XCTAssertEqual(address.name_len, 6)
        XCTAssertEqual(address.device_id, 1)

        let fromCAddress = String(cString: address.name)
        XCTAssertEqual(fromCAddress, stringAddress)
    }

}
