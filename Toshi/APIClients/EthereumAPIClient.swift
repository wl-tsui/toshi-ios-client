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
import Haneke

typealias BalanceCompletion = ((_ balance: NSDecimalNumber, _ error: ToshiError?) -> Void)
typealias WalletItemsCompletion = ((_ items: [WalletItem], _ error: ToshiError?) -> Void)

final class EthereumAPIClient {

    static let shared: EthereumAPIClient = EthereumAPIClient()

    private var mainTeapot: Teapot

    private var switchedNetworkTeapot: Teapot

    private var activeTeapot: Teapot {
        if NetworkSwitcher.shared.isDefaultNetworkActive {
            return mainTeapot
        } else {
            return switchedNetworkTeapot
        }
    }

    private static var teapotUrl: String {
        return NetworkSwitcher.shared.activeNetworkBaseUrl
    }

    private let cache = Shared.stringCache

    private static let CachedBalanceKey = "CachedBalanceKey"

    convenience init(mockTeapot: MockTeapot) {
        self.init()
        self.switchedNetworkTeapot = mockTeapot
        self.mainTeapot = mockTeapot
    }

    private init() {
        mainTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)
        switchedNetworkTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)
    }

    private func timestamp(_ teapot: Teapot, _ completion: @escaping ((_ timestamp: String?, _ error: ToshiError?) -> Void)) {
        teapot.get("/v1/timestamp") { result in
            APITimestamp.parse(from: result, completion)
        }
    }

    // MARK: - Transactions

    func createUnsignedTransaction(parameters: [String: Any], completion: @escaping ((_ unsignedTransaction: String?, _ error: ToshiError?) -> Void)) {

        transactionSkeleton(for: parameters) { skeleton, error in
            let transaction = skeleton.transaction

            DispatchQueue.main.async {
                completion(transaction, error)
            }
        }
    }

    func transactionSkeleton(for parameters: [String: Any], completion: @escaping ((_ skeleton: TransactionSkeleton, _ error: ToshiError?) -> Void)) {

        let json = RequestParameter(parameters)

        self.activeTeapot.post("/v1/tx/skel", parameters: json) { result in
            var skeleton = TransactionSkeleton.empty
            var resultError: ToshiError?

            defer {
                DispatchQueue.main.async {
                    completion(skeleton, resultError)
                }
            }

            switch result {
            case .success(let json, _):
                guard let data = json?.data else {
                    resultError = .invalidPayload
                    return
                }

                TransactionSkeleton.fromJSONData(data,
                                                 successCompletion: { result in
                                                    skeleton = result
                                                 },
                                                 errorCompletion: { parsingError in
                                                    resultError = parsingError
                                                 })
            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error, errorDescription: Localized.payment_error_message)
            }
        }
    }

    func sendSignedTransaction(originalTransaction: String, transactionSignature: String, completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {
        let params = [
            TransactionSkeleton.CodingKeys.transaction.rawValue: originalTransaction,
            "signature": transactionSignature
        ]
        sendSignedTransaction(params: params, completion: completion)
    }

    func sendSignedTransaction(signedTransaction: String, completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {
        let params = [
            TransactionSkeleton.CodingKeys.transaction.rawValue: signedTransaction
        ]
        sendSignedTransaction(params: params, completion: completion)
    }

    private func sendSignedTransaction(params: [String: String], completion: @escaping ((_ success: Bool, _ transactionHash: String?, _ error: ToshiError?) -> Void)) {

        timestamp(activeTeapot) { timestamp, error in
            guard let timestamp = timestamp else {
                DispatchQueue.main.async {
                    completion(false, nil, error)
                }
                return
            }

            let path = "/v1/tx"

            guard let headers = try? HeaderGenerator.createHeaders(timestamp: timestamp, path: path, payloadDictionary: params) else {
                DispatchQueue.main.async {
                    completion(false, nil, .invalidPayload)
                }
                return
            }

            let json = RequestParameter(params)

            self.activeTeapot.post(path, parameters: json, headerFields: headers) { result in
                var success = false
                var transactionHash: String?
                var toshiError: ToshiError?

                defer {
                    DispatchQueue.main.async {
                        completion(success, transactionHash, toshiError)
                    }
                }

                switch result {
                case .success(let json, _):
                    guard let hash = json?.dictionary?["tx_hash"] as? String else {
                        CrashlyticsLogger.log("Error recovering transaction hash")
                        fatalError("Error recovering transaction hash")
                    }

                    transactionHash = hash
                    success = true
                case .failure:
                    toshiError = ToshiError(errorResult: result)
                }
            }
        }
    }

    // MARK: - Balance

    func getBalance(address: String = Cereal.shared.paymentAddress, cachedBalanceCompletion: @escaping BalanceCompletion = { balance, _ in }, fetchedBalanceCompletion: @escaping BalanceCompletion) {

        cache.fetch(key: EthereumAPIClient.CachedBalanceKey).onSuccess { numberString in
            let cachedBalance: NSDecimalNumber = NSDecimalNumber(string: numberString)
            cachedBalanceCompletion(cachedBalance, nil)
        }

        self.activeTeapot.get("/v1/balance/\(address)") { [weak self] (result: NetworkResult) in
            var balance: NSDecimalNumber = .zero
            var resultError: ToshiError?

            defer {
                DispatchQueue.main.async {
                    fetchedBalanceCompletion(balance, resultError)
                }
            }

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    resultError = .invalidResponseStatus(response.statusCode)
                    return
                }

                guard let json = json?.dictionary else {
                    resultError = .invalidResponseJSON
                    return
                }

                let unconfirmedBalanceString = json["unconfirmed_balance"] as? String ?? "0"
                let unconfirmedBalance = NSDecimalNumber(hexadecimalString: unconfirmedBalanceString)

                Profile.current?.balance = unconfirmedBalance
                balance = unconfirmedBalance
            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
            }

            self?.cache.set(value: balance.stringValue, key: EthereumAPIClient.CachedBalanceKey)
        }
    }

    // MARK: - Collectibles

    func getCollectible(address: String = Cereal.shared.paymentAddress, contractAddress: String, completion: @escaping ((Collectible?, ToshiError?) -> Void)) {
        var collectiblesTeapot = self.activeTeapot

        // If we are on debug (specified in "other swift flags") we will mock out the collectiblesince they are only on production
        #if DEBUG
            if !(collectiblesTeapot is MockTeapot) {
                collectiblesTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClient.self), mockFilename: "getACollectible")
            } // else, we're testing and want to use that mock teapot.
        #endif

        collectiblesTeapot.get("/v1/collectibles/\(address)/\(contractAddress)") { result in
            var resultError: ToshiError?
            var resultItem: Collectible?

            defer {
                DispatchQueue.main.async {
                    completion(resultItem, resultError)
                }
            }

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    resultError = .invalidResponseStatus(response.statusCode)
                    return
                }

                guard let data = json?.data else {
                    resultError = .invalidPayload
                    return
                }

                Collectible.fromJSONData(data,
                                         successCompletion: { collectible in
                                            resultItem = collectible
                                         },
                                         errorCompletion: { parsingError in
                                            resultError = parsingError
                                         })
            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
            }
        }
    }

    func getCollectibles(address: String = Cereal.shared.paymentAddress, completion: @escaping WalletItemsCompletion) {
        var collectiblesTeapot = self.activeTeapot

        // If we are on debug (specified in "other swift flags") we will mock out the collectibles since they are only on production
        #if DEBUG
            if !(collectiblesTeapot is MockTeapot) {
                collectiblesTeapot = MockTeapot(bundle: Bundle(for: EthereumAPIClient.self), mockFilename: "getCollectibles")
            } // else, we're testing and want to use that mock teapot.
        #endif

        collectiblesTeapot.get("/v1/collectibles/\(address)") { (result: NetworkResult) in
            var resultError: ToshiError?
            var resultItems = [Collectible]()

            defer {
                DispatchQueue.main.async {
                    completion(resultItems, resultError)
                }
            }

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    resultError = .invalidResponseStatus(response.statusCode)
                    return
                }

                guard let data = json?.data else {
                    resultError = .invalidPayload
                    return
                }

                CollectibleResults.fromJSONData(data,
                                                successCompletion: { results in
                                                    resultItems.append(contentsOf: results.collectibles)
                                                },
                                                errorCompletion: { parsingError in
                                                    resultError = parsingError
                                                })
            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
            }
        }
    }

    // MARK: - Tokens

    func getTokens(address: String = Cereal.shared.paymentAddress, completion: @escaping WalletItemsCompletion) {

        self.activeTeapot.get("/v1/tokens/\(address)") { (result: NetworkResult) in
            var resultError: ToshiError?
            var resultItems = [Token]()

            defer {
                DispatchQueue.main.async {
                    completion(resultItems, resultError)
                }
            }

            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else {
                    resultError = .invalidResponseStatus(response.statusCode)
                    return
                }

                guard let data = json?.data else {
                    resultError = .invalidPayload
                    return
                }

                TokenResults.fromJSONData(data,
                                          successCompletion: { results in
                                            resultItems.append(contentsOf: results.tokens)
                                          },
                                          errorCompletion: { parsingError in
                                            resultError = parsingError
                                          })

            case .failure(_, _, let error):
                resultError = ToshiError(withTeapotError: error)
            }
        }
    }

    // MARK: - Push Notifications

    func registerForMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.registerForPushNotifications(timestamp, teapot: self.mainTeapot) { _, _ in }
        }
    }

    func registerForSwitchedNetworkPushNotificationsIfNeeded(completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        guard NetworkSwitcher.shared.isDefaultNetworkActive == false else {
            completion?(true, nil)
            return
        }

        switchedNetworkTeapot.baseURL = URL(string: NetworkSwitcher.shared.activeNetworkBaseUrl)!

        timestamp(switchedNetworkTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.registerForPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    func deregisterFromMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.deregisterFromPushNotifications(timestamp, teapot: self.mainTeapot)
        }
    }

    func deregisterFromSwitchedNetworkPushNotifications(completion: @escaping ((_ success: Bool, _ message: String?) -> Void) = { (Bool, String) in }) {

        timestamp(switchedNetworkTeapot) { timestamp, _ in
            guard let timestamp = timestamp else { return }
            self.deregisterFromPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    private func registerForPushNotifications(_ timestamp: String, teapot: Teapot, completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        updatePushNotificationRegistration(register: true, timestamp: timestamp, teapot: teapot, completion: completion)
    }

    private func deregisterFromPushNotifications(_ timestamp: String, teapot: Teapot, completion: @escaping ((_ success: Bool, _ message: String?) -> Void) = { (Bool, String) in }) {
        updatePushNotificationRegistration(register: false, timestamp: timestamp, teapot: teapot, completion: completion)
    }

    private func updatePushNotificationRegistration(register: Bool,
                                                    timestamp: String,
                                                    teapot: Teapot,
                                                    completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        var path = "/v1/apn/register"
        if !register {
            var path = "/v1/apn/deregister"
        }

        DispatchQueue.main.async {
            // This has to be on the main queue to get info about push stuff to send to the server.
            let pushInfo = APIPushInfo.defaultInfo
            guard let jsonData = pushInfo.toOptionalJSONData() else {
                completion?(false, nil)
                return
            }

            guard let headers = try? HeaderGenerator.createHeaders(timestamp: timestamp, path: path, payloadData: jsonData) else {
                completion?(false, nil)
                return
            }

            let json = RequestParameter(jsonData)

            teapot.post(path, parameters: json, headerFields: headers) { result in
                var success = false
                var message: String?

                defer {
                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(success, message)
                        }
                    } // else, nothing to do.
                }

                switch result {
                case .success(let json, let response):
                    if register {
                        DLog("\n +++ Registered for :\(teapot.baseURL)")
                    } else {
                        DLog("\n --- DE-registered from :\(teapot.baseURL)")
                    }
                    success = true
                    message = "json:\(json?.dictionary ?? [String: Any]()), response: \(response)"
                case .failure(let json, let response, let error):
                    message = "json:\(json?.dictionary ?? [String: Any]()), response: \(response), error: \(error)"
                }
            }
        }
    }
}
