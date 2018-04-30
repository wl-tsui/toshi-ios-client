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
import Teapot

struct APITimestamp: Codable {

    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case
        timestamp
    }

    static func parse(from result: NetworkResult, _ completion: @escaping ((_ timestamp: String?, _ error: ToshiError?) -> Void)) {
        var timestamp: String?
        var errorEncountered: ToshiError?

        defer {
            completion(timestamp, errorEncountered)
        }

        switch result {
        case .success(let json, _):
            guard let data = json?.data else {
                CrashlyticsLogger.log("Timestamp data was null!")
                errorEncountered = .invalidPayload
                return
            }

            APITimestamp.fromJSONData(data,
                                      successCompletion: { result in
                                        timestamp = String(result.timestamp)
                                      },
                                      errorCompletion: { error in
                                        CrashlyticsLogger.log("Error parsing timestamp: \(error)")
                                        fatalError()
                                      })
        case .failure(_, _, let error):
            errorEncountered = ToshiError(withTeapotError: error)
        }
    }
}
