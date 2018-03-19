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
import Foundation
import Teapot

class DirectoryAPIClientTests: XCTestCase {

    func testGetDappsFrontPage() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "dappsFrontPage")

        let directoryAPIClient = DirectoryAPIClient(teapot: mockTeapot)

        let expectation = XCTestExpectation(description: "Get Dapps")

        directoryAPIClient.getDappsFrontPage { frontPageResult, _ in
            guard let frontPageResult = frontPageResult else {
                XCTAssert(false)
                return
            }
            XCTAssertEqual(frontPageResult.categories.count, 6)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetQueriedDapps() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "queriedDappsResults")

        let directoryAPIClient = DirectoryAPIClient(teapot: mockTeapot)

        let expectation = XCTestExpectation(description: "Get Dapps")

        let queryData = DappsQueryData()

        directoryAPIClient.getQueriedDapps(queryData: queryData) { dappsResult, _ in
            guard let dappsResult = dappsResult else {
                XCTAssert(false)
                return
            }
            XCTAssertEqual(dappsResult.results.dapps.count, 10)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
