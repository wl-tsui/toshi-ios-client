//
//  RegistrationTests.swift
//  CPlaygroundTests
//
//  Created by Ellen Shapiro (Work) on 1/30/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import XCTest

class RegistrationTests: XCTestCase {

    func testGeneratingIDandKeyPair() {
        XCTAssertTrue(SignalWrapper.generateAndSaveRegistrationID())
        XCTAssertGreaterThan(SignalWrapper.registrationID(), 0)

        guard SignalWrapper.identityKeyPair() != nil else {
            XCTFail("Identity key pair not created!")
            return
        }
    }
}
