import XCTest
import UIKit
import Teapot
@testable import Toshi

class IDAPIClientTests: XCTestCase {
    let canonicalAddress = "0x037be053f866be6ee6dda11f258bd871b701a8d7"

    func testFetchProfilesFrontPage() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientTests.self), mockFilename: "profilesFrontPage")
        let idAPIClient = IDAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "fetches profiles front page")

        idAPIClient.fetchProfilesFrontPage { frontPageResult, _ in
            guard let frontPageResult = frontPageResult else {
                XCTFail("frontPageResult is nil")
                return
            }

            XCTAssertEqual(frontPageResult.map { $0.name }, ["Popular Groups", "Featured Bots", "Public Users"])

            guard frontPageResult.count == 3 else {
                XCTFail("json result should have 3 sections")
                return
            }

            let popularGroups = frontPageResult[0]
            XCTAssertEqual(popularGroups.profiles.first?.type, "groupbot")
            XCTAssertEqual(popularGroups.profiles.first?.name, "Group Chat")
            XCTAssertEqual(popularGroups.profiles.first?.username, "groupchat")
            XCTAssertEqual(popularGroups.profiles.first?.toshiId, "0x3174bea20e9d4dacdc5950a029fd71bb38f871eb")
            XCTAssertEqual(popularGroups.profiles.first?.avatar, "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x3174bea20e9d4dacdc5950a029fd71bb38f871eb_e7aa2e.png")

            let featuredBots = frontPageResult[1]
            XCTAssertEqual(featuredBots.profiles.map { $0.type }, ["bot", "bot", "bot"])
            XCTAssertEqual(featuredBots.profiles.map { $0.name }, ["Spambot", "Adbot (dev)", "ERC20 Management Bot"])
            XCTAssertEqual(featuredBots.profiles.map { $0.username }, ["spambot7777", "adbot", "erc20bot"])
            XCTAssertEqual(featuredBots.profiles.map { $0.toshiId }, ["0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b",
                                                                      "0xdf0096052836251b0fafd4f0f12771deea5c8748",
                                                                      "0x4d118e7d45a0c5688bbe0f86172bcbe5dd7bdede"])
            XCTAssertEqual(featuredBots.profiles.map { $0.avatar }, ["https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x8f9bdb7f562ccdedf3c24cf25e9cece9df62138b_fe3ea8.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0xdf0096052836251b0fafd4f0f12771deea5c8748_bef532.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x4d118e7d45a0c5688bbe0f86172bcbe5dd7bdede_208231.png"])
            XCTAssertEqual(featuredBots.profiles.map { $0.paymentAddress }, ["0x011c6dd9565b8b83e6a9ee3f06e89ece3251ef2f",
                                                                             "0x9a1576dbcdd7b20b239078d1b31885b04807c79a",
                                                                             "0x3754eb95fcb563013fd19e2068b71de46e53d5cc"])
            XCTAssertEqual(featuredBots.profiles.map { $0.isPublic }, [true, true, true])
            XCTAssertEqual(featuredBots.profiles.map { $0.reputationScore }, [4.0, 2.7, 2.3])
            XCTAssertEqual(featuredBots.profiles.map { $0.averageRating }, [4.8, 3.6, 3.3])
            XCTAssertEqual(featuredBots.profiles.map { $0.reviewCount }, [16, 8, 3])

            let publicUsers = frontPageResult[2]

            XCTAssertEqual(publicUsers.profiles.map { $0.type }, ["user", "user"])
            XCTAssertEqual(publicUsers.profiles.map { $0.name }, ["Session Tester", "Marijn Schilling"])
            XCTAssertEqual(publicUsers.profiles.map { $0.username }, ["the_session", "marijnschilling"])
            XCTAssertEqual(publicUsers.profiles.map { $0.toshiId }, ["0x1bdbcf6c9dacf56f10dd02e2ec47c0c4d569429f",
                                                                      "0x6f70800cb47f7f84b6c71b3693fc02595eae7378"])
            XCTAssertEqual(publicUsers.profiles.map { $0.avatar }, ["https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x1bdbcf6c9dacf56f10dd02e2ec47c0c4d569429f_6cdd7c.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x6f70800cb47f7f84b6c71b3693fc02595eae7378_88c9dd.png"])
            XCTAssertEqual(publicUsers.profiles.map { $0.paymentAddress }, ["0x80142fee06e8debf4e6cc7298bb3832e7345ea8b",
                                                                             "0x1ad0bb2d14595fa6ad885e53eaaa6c82339f9b98"])
            XCTAssertEqual(publicUsers.profiles.map { $0.isPublic }, [true, true])
            XCTAssertEqual(publicUsers.profiles.map { $0.description }, ["", "iOSdevelicious"])
            XCTAssertEqual(publicUsers.profiles.map { $0.location }, ["", "De Hoofdstad"])

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testSearchProfilesOfUserType() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientTests.self), mockFilename: "searchUserProfiles")
        let idAPIClient = IDAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "searches user profiles")

        idAPIClient.searchProfilesOfType(ProfileType.user.typeString, for: "m") { searchedProfilesResults, type, error in
            XCTAssertNil(error)
            XCTAssertEqual(type, ProfileType.user.typeString)

            guard let searchedProfilesResults = searchedProfilesResults else {
                XCTFail("searchedProfilesResults is nil")
                return
            }

            XCTAssertEqual(searchedProfilesResults.map { $0.type }, ["user", "user", "user"])
            XCTAssertEqual(searchedProfilesResults.map { $0.name }, ["4654654654", "Winter", "www"])
            XCTAssertEqual(searchedProfilesResults.map { $0.username }, ["Weiner0234516546545", "winter", "www"])
            XCTAssertEqual(searchedProfilesResults.map { $0.toshiId }, ["0xeb2213128d8bc817e81e7e996be6dc4cbd368e63",
                                                                      "0x60c7c1935f787a6474b84f3a997263080bb20b1c",
                                                                      "0x9612feb3e14c46144b3d14438000b42c7e19cf74"])
            XCTAssertEqual(searchedProfilesResults.map { $0.avatar }, ["https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0xeb2213128d8bc817e81e7e996be6dc4cbd368e63_c4b731.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x60c7c1935f787a6474b84f3a997263080bb20b1c_b1627f.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/identicon/0xb3c8b75d0da12884e88e31bc0e04c969ccccf722.png"])
            XCTAssertEqual(searchedProfilesResults.map { $0.paymentAddress }, ["0xb0b90c23e3c1249e78b330f6baa1e32c47b8e6bc",
                                                                             "0x78972bdd6c8560dea15dfec8bcd947c08cac9c6e",
                                                                             "0xb3c8b75d0da12884e88e31bc0e04c969ccccf722"])
            XCTAssertEqual(searchedProfilesResults.map { $0.isPublic }, [true, false, false])

            XCTAssertEqual(searchedProfilesResults.map { $0.description }, ["Im cool", "", ""])
            XCTAssertEqual(searchedProfilesResults.map { $0.location }, ["Unknown", "Bonn ", ""])

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testSearchProfilesOfGroupType() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientTests.self), mockFilename: "searchGroupProfiles")
        let idAPIClient = IDAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "searches user profiles")

        idAPIClient.searchProfilesOfType(ProfileType.group.typeString, for: "g") { searchedProfilesResults, type, error in
            XCTAssertNil(error)
            XCTAssertEqual(type, ProfileType.group.typeString)

            guard let searchedProfilesResults = searchedProfilesResults else {
                XCTFail("searchedProfilesResults is nil")
                return
            }

            XCTAssertEqual(searchedProfilesResults.first?.type, "groupbot")
            XCTAssertEqual(searchedProfilesResults.first?.name, "Group Chat")
            XCTAssertEqual(searchedProfilesResults.first?.username, "groupchat")
            XCTAssertEqual(searchedProfilesResults.first?.toshiId, "0x3174bea20e9d4dacdc5950a029fd71bb38f871eb")
            XCTAssertEqual(searchedProfilesResults.first?.avatar, "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x3174bea20e9d4dacdc5950a029fd71bb38f871eb_e7aa2e.png")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testSearchProfilesOfBotType() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientTests.self), mockFilename: "searchBotProfiles")
        let idAPIClient = IDAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "searches user profiles")

        idAPIClient.searchProfilesOfType(ProfileType.bot.typeString, for: "m") { searchedProfilesResults, type, error in
            XCTAssertNil(error)
            XCTAssertEqual(type, ProfileType.bot.typeString)

            guard let searchedProfilesResults = searchedProfilesResults else {
                XCTFail("searchedProfilesResults is nil")
                return
            }

            XCTAssertEqual(searchedProfilesResults.map { $0.type }, ["bot", "bot"])
            XCTAssertEqual(searchedProfilesResults.map { $0.name }, ["ERC20 Management Bot", "DEV ERC20 Bot"])
            XCTAssertEqual(searchedProfilesResults.map { $0.username }, ["erc20bot", "dev___erc20bot"])
            XCTAssertEqual(searchedProfilesResults.map { $0.toshiId }, ["0x4d118e7d45a0c5688bbe0f86172bcbe5dd7bdede",
                                                                      "0x2618ee32ca088dbd0ca3bcdb2d704af661c45d1c"])
            XCTAssertEqual(searchedProfilesResults.map { $0.avatar }, ["https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x4d118e7d45a0c5688bbe0f86172bcbe5dd7bdede_208231.png",
                                                                     "https://bucketeer-2d10c7cb-4f39-4e94-82a5-99df6af2477f.s3.amazonaws.com/public/avatar/0x2618ee32ca088dbd0ca3bcdb2d704af661c45d1c_89acb6.png"])
            XCTAssertEqual(searchedProfilesResults.map { $0.paymentAddress }, ["0x3754eb95fcb563013fd19e2068b71de46e53d5cc",
                                                                             "0x518e30afa33ef0138a29d443e604a6fa8311a2c6"])
            XCTAssertEqual(searchedProfilesResults.map { $0.isPublic }, [true, false])
            XCTAssertEqual(searchedProfilesResults.map { $0.reputationScore }, [2.3, 0.0])
            XCTAssertEqual(searchedProfilesResults.map { $0.averageRating }, [3.3, 0])
            XCTAssertEqual(searchedProfilesResults.map { $0.reviewCount }, [3, 0])

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testCreatePathForSearchQuery() {
        let mockTeapot = MockTeapot(bundle: Bundle(for: IDAPIClientTests.self), mockFilename: "searchBotProfiles")
        let idAPIClient = IDAPIClient(teapot: mockTeapot, cacheEnabled: false)

        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.bot.typeString, with: ""), "/v2/search?type=bot&query=")
        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.bot.typeString, with: "something"), "/v2/search?type=bot&query=something")

        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.group.typeString, with: ""), "/v2/search?type=groupbot&query=")
        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.group.typeString, with: "something"), "/v2/search?type=groupbot&query=something")

        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.user.typeString, with: ""), "/v2/search?type=user&query=")
        XCTAssertEqual(idAPIClient.createPathFor(ProfileType.user.typeString, with: "something"), "/v2/search?type=user&query=something")
    }
}
