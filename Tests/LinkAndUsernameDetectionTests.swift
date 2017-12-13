//
//  LinkAndUsernameDetectionTests.swift
//  Tests
//
//  Created by Igor Ranieri on 13.12.17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import Foundation
import XCTest
@testable import Toshi

class LinkAndUsernameDetectionTests: XCTestCase {
    func test() {
        let cell = MessagesTextCell()
        cell.detectUsernameLinksIfNeeded()
    }
}
