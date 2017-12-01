//
//  TokenUserTests.swift
//  Tests
//
//  Created by Ellen Shapiro (Work) on 11/27/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import XCTest
@testable import Toshi

class TokenUserTests: XCTestCase {
    
    func testStrippingAtSymbol() {
        let withAtSymbol = "@HomerSimpson"
        let withoutAtSymbol = "BartSimpson"
        
        XCTAssertEqual(TokenUser.name(from: withAtSymbol), "HomerSimpson")
        XCTAssertEqual(TokenUser.name(from: withoutAtSymbol), withoutAtSymbol)
    }
}
