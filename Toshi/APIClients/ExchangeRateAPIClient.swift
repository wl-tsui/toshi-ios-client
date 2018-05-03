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

let ExchangeRateClient = ExchangeRateAPIClient.shared

final class ExchangeRateAPIClient {

    static let shared: ExchangeRateAPIClient = ExchangeRateAPIClient()

    private static let collectionKey = "ethereumExchangeRate"
    private let currenciesCacheKey = "currenciesCacheKey"

    private let cache = Shared.dataCache

    var teapot: Teapot
    var baseURL: URL

    var exchangeRate: Decimal {
        if let rate = Yap.sharedInstance.retrieveObject(for: ExchangeRateAPIClient.collectionKey) as? Decimal {
            return rate
        } else {
            return 0
        }
    }

    convenience init(teapot: Teapot, cacheEnabled: Bool = true) {
        self.init()
        self.teapot = teapot

        if !cacheEnabled {
            cache.removeAll()
        }
    }

    init() {
        baseURL = URL(string: ToshiExchangeRateServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        updateRate()

        let fiveMinutes: TimeInterval = 60 * 5
        Timer.scheduledTimer(withTimeInterval: fiveMinutes, repeats: true) { [weak self] _ in
            self?.updateRate()
        }
    }

    func updateRateAndNotify() {
        updateRate { _ in
            NotificationCenter.default.post(name: .localCurrencyUpdated, object: nil)
        }
    }

    func updateRate(_ completion: @escaping ((_ rate: Decimal?) -> Void) = { _ in }) {
        getRate { rate in
            if rate != nil {
                Yap.sharedInstance.insert(object: rate, for: ExchangeRateAPIClient.collectionKey)
            }

            completion(rate)
        }
    }

    func getRate(_ completion: @escaping ((_ rate: Decimal?) -> Void)) {
        let code = Profile.current?.localCurrency ?? Profile.defaultCurrency

        teapot.get("/v1/rates/ETH/\(code)") { result in
            var retrievedRate: Decimal?

            defer {
                DispatchQueue.main.async {
                    completion(retrievedRate)
                }
            }

            switch result {
            case .success(let json, _):
                guard
                    let dictionary = json?.dictionary,
                    let rate = dictionary["rate"] as? String,
                    let doubleValue = Double(rate) else {
                        return
                }

                retrievedRate = Decimal(doubleValue)
            case .failure(_, _, let error):
                DLog(error.localizedDescription)
            }
        }
    }

    func getCurrencies(_ completion: @escaping (([Currency]) -> Void)) {
        cache.fetch(key: currenciesCacheKey).onSuccess { data in
            CurrenciesResults.fromJSONData(data,
                                           successCompletion: { results in
                                            completion(results.currencies)
                                           },
                                           errorCompletion: nil)
        }

        teapot.get("/v1/currencies") { [weak self] result in
            var currencies = [Currency]()

            defer {
                DispatchQueue.main.async {
                    completion(currencies)
                }
            }

            switch result {
            case .success(let json, _):
                guard let data = json?.data else {
                    return
                }

                CurrenciesResults.fromJSONData(data,
                                               successCompletion: { results in
                                                currencies = results.currencies
                                               },
                                               errorCompletion: nil)
                guard let strongSelf = self else { return }
                strongSelf.cache.set(value: data, key: strongSelf.currenciesCacheKey)
            case .failure(_, _, let error):
                DLog(error.localizedDescription)
            }
        }
    }
}
