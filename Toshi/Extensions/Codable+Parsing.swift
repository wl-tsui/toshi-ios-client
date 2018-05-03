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

import Foundation

extension Decodable {

    static func fromJSONData(_ data: Data,
                             with decoder: JSONDecoder = JSONDecoder(),
                             successCompletion: (Self) -> Void,
                             errorCompletion: ((ToshiError) -> Void)?) {

        do {
            let decoded = try decoder.decode(Self.self, from: data)
            successCompletion(decoded)
        } catch let error {
            DLog("Parsing error: \(error)")
            errorCompletion?(.invalidResponseJSON)
        }
    }

    static func optionalFromJSONData(_ data: Data,
                                     with decoder: JSONDecoder = JSONDecoder()) -> Self? {
        return try? decoder.decode(Self.self, from: data)
    }
}

extension Encodable {

    func toJSONData(with encoder: JSONEncoder = JSONEncoder(),
                    successCompletion: (Data) -> Void,
                    errorCompletion: (Error) -> Void) {
        do {
            let encoded = try encoder.encode(self)
            successCompletion(encoded)
        } catch let error {
            errorCompletion(error)
        }
    }

    func toOptionalJSONData(with encoder: JSONEncoder = JSONEncoder()) -> Data? {
        return try? encoder.encode(self)
    }
}
