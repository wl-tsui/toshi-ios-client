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
import Teapot

let ExchangeRateClient = ExchangeRateAPIClient.shared

@objc public final class ExchangeRateAPIClient: NSObject {

    @objc public static let shared: ExchangeRateAPIClient = ExchangeRateAPIClient()

    private static let collectionKey = "ethereumExchangeRate"

    private var timer: Timer?

    public var teapot: Teapot
    public var baseURL: URL

    public var exchangeRate: Decimal {
        if let rate = Yap.sharedInstance.retrieveObject(for: ExchangeRateAPIClient.collectionKey) as? Decimal {
            return rate
        } else {
            return 0
        }
    }

    convenience init(teapot: Teapot) {
        self.init()
        self.teapot = teapot
    }

    override init() {
        baseURL = URL(string: ToshiExchangeRateServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(userDidSignOut(_:)), name: .UserDidSignOut, object: nil)
    }

    @objc private func userDidSignOut(_: Notification) {
        timer?.invalidate()
        timer = nil

        print("\n\n --- Invalidating exchange rate update timer")
    }

    @objc public func setupForSession() {
        print("\n\n --- Setting up exchange rate update timer")
        updateRate()

        timer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.updateRate()
        }
    }

    public func updateRate(_ completion: @escaping ((_ rate: Decimal?) -> Void) = { _ in }) {
        getRate { rate in
            if rate != nil {
                Yap.sharedInstance.insert(object: rate, for: ExchangeRateAPIClient.collectionKey)
            }

            DispatchQueue.main.async {
                completion(rate)
            }
        }
    }

    public func getRate(_ completion: @escaping ((_ rate: Decimal?) -> Void)) {
        let code = TokenUser.current?.localCurrency ?? TokenUser.defaultCurrency

        self.teapot.get("/v1/rates/ETH/\(code)") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary, let usd = json["rate"] as? String, let doubleValue = Double(usd) as Double? else {
                    completion(nil)
                    return
                }

                completion(Decimal(doubleValue))
            case .failure(_, _, let error):
                print(error.localizedDescription)
                completion(nil)
            }
        }
    }

    public func getCurrencies(_ completion: @escaping (([Currency]) -> Void)) {
        self.teapot.get("/v1/currencies") { (result: NetworkResult) in
            var results: [Currency] = []

            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary, let currencies = json["currencies"] as? [[String : String]] else {
                    completion([])
                    return
                }

                var validResults: [Currency] = []
                for currency in currencies {
                    guard let code = currency["code"], let name = currency["name"] else { continue }

                    validResults.append(Currency(code, name))
                }

                results = validResults
            case .failure(_, _, let error):
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
}
