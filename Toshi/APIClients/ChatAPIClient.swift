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
import SweetFoundation

final class ChatAPIClient {

    static let shared: ChatAPIClient = ChatAPIClient()

    var teapot: Teapot

    var baseURL: URL

    private init() {
        guard let tokenChatServiceBaseURL = Bundle.main.object(forInfoDictionaryKey: "TokenChatServiceBaseURL") as? String, let url = URL(string: tokenChatServiceBaseURL) else { fatalError("TokenChatServiceBaseURL should be provided")}

        baseURL = url
        teapot = Teapot(baseURL: baseURL)
    }

    func fetchTimestamp(_ completion: @escaping ((_ timestamp: String?, _ error: ToshiError?) -> Void)) {

        self.teapot.get("/v1/accounts/bootstrap/") { result in
            APITimestamp.parse(from: result, completion)
        }
    }

    func registerUser(completion: @escaping ((_ success: Bool) -> Void) = { (Bool) in }) {
        fetchTimestamp { timestamp, _ in
            DispatchQueue.main.async {
                // This needs to be called on the main thread to avoid a race condition with creating the user.
                guard let timestamp = timestamp else {
                    completion(false)
                    return
                }

                let cereal = Cereal.shared
                let parameters = UserBootstrapParameter()
                let path = "/v1/accounts/bootstrap"
                let payload = parameters.payload

                guard let headers = try? HeaderGenerator.createHeaders(timestamp: timestamp, path: path, method: .PUT, payloadDictionary: payload) else {
                    completion(false)
                    return
                }

                let requestParameter = RequestParameter(payload)

                self.teapot.put(path, parameters: requestParameter, headerFields: headers) { result in
                    var succeeded = false

                    defer {
                        DispatchQueue.main.async {
                            completion(succeeded)
                        }
                    }

                    switch result {
                    case .success(_, let response):
                        guard response.statusCode == 204 else {
                            return
                        }

                        TSAccountManager.sharedInstance().storeServerAuthToken(parameters.password, signalingKey: parameters.signalingKey)
                        ALog("Successfully registered chat user with address: \(cereal.address)")
                        succeeded = true
                    case .failure:
                        break
                    }
                }
            }
        }
    }
}
