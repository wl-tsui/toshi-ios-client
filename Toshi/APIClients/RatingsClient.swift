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

import UIKit
import Teapot

class RatingsClient: NSObject {
    static let shared: RatingsClient = RatingsClient()

    var teapot: Teapot

    var baseURL: URL

    convenience init(teapot: Teapot) {
        self.init()
        self.teapot = teapot
    }

    private override init() {
        baseURL = URL(string: ToshiRatingsServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        super.init()
    }

    private func fetchTimestamp(_ completion: @escaping ((_ timestamp: String?, _ error: ToshiError?) -> Void)) {
        self.teapot.get("/v1/timestamp") { result in
            APITimestamp.parse(from: result, completion)
        }
    }

    func submit(userId: String, rating: Int, review: String, completion: @escaping ((_ success: Bool, _ error: ToshiError?) -> Void)) {
        fetchTimestamp { timestamp, error in

            guard let timestamp = timestamp else {
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }
            let cereal = Cereal.shared
            let path = "/v1/review/submit"
            let payload: [String: Any] = [
                "rating": rating,
                "reviewee": userId,
                "review": review
            ]

            guard let headers = try? HeaderGenerator.createHeaders(timestamp: timestamp, path: path, payloadDictionary: payload) else {
                DispatchQueue.main.async {
                    completion(false, .invalidPayload)
                }
                return
            }

            let json = RequestParameter(payload)

            self.teapot.post(path, parameters: json, headerFields: headers) { result in
                var success = false
                var toshiError: ToshiError?

                defer {
                    DispatchQueue.main.async {
                        completion(success, toshiError)
                    }
                }

                switch result {
                case .success:
                    success = true
                case .failure:
                    toshiError = ToshiError(errorResult: result)
                }
            }
        }
    }

    func scores(for userId: String, completion: @escaping ((_ ratingScore: RatingScore) -> Void)) {
        self.teapot.get("/v1/user/\(userId)") { result in
            var ratingScore = RatingScore.zero

            defer {
                DispatchQueue.main.async {
                    completion(ratingScore)
                }
            }

            switch result {
            case .success(let json, _):
                guard let data = json?.data else {
                    return
                }

                RatingScore.fromJSONData(data,
                                         successCompletion: { rating in
                                            ratingScore = rating
                                         },
                                         errorCompletion: nil)
            case .failure(let error):
                DLog("Error getting rating: \(error)")
            }
        }
    }
}
