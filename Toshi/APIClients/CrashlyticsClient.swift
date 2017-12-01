// Copyright (c) 2017 Token Browser, Inc
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

import Foundation

typealias KeyTitle = String

extension KeyTitle {
    static var error = "error"
    static var occurred = "occurred"
    static var resultString = "result string"
}

@objc final class CrashlyticsClient: NSObject {

    @objc static func start(with apiKey: String) {
        Crashlytics.start(withAPIKey: apiKey)
        Fabric.with([Crashlytics.self])
    }

    @objc static func setupForUser(with toshiID: String) {
        Crashlytics.sharedInstance().setUserIdentifier(toshiID)
    }
}

@objc final class CrashlyticsLogger: NSObject {

    @objc static func log(_ string: String, attributes: [KeyTitle: Any]? = nil) {
        CLSLogv("%@", getVaList([string]))

        var resultAttributes: [String: Any] = ["user_id": Cereal.shared.address]
        attributes?.forEach { key, value in resultAttributes[key] = value }

        Answers.logCustomEvent(withName: string, customAttributes: resultAttributes)
    }
}
