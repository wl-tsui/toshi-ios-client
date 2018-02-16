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

typealias WalletItemResults = (_ apps: [WalletItem]?, _ error: ToshiError?) -> Void

enum WalletItemType: Int {
    case token
    case collectibles
}

protocol WalletDatasourceDelegate: class {
    func walletDatasourceDidReload()
}

final class WalletDatasource {

    weak var delegate: WalletDatasourceDelegate?

    var itemsType: WalletItemType = .token {
        didSet {
            loadItems()
        }
    }

    private var items: [WalletItem] = []

    init(delegate: WalletDatasourceDelegate?) {
        self.delegate = delegate
    }

    var numberOfItems: Int {
        return items.count
    }

    var isEmpty: Bool {
        return numberOfItems == 0
    }

    var emptyStateTitle: String {
        switch itemsType {
        case .token:
            return Localized("wallet_empty_tokens_title")
        case .collectibles:
            return Localized("wallet_empty_collectibles_title")
        }
    }

    func item(at index: Int) -> WalletItem? {
        guard index < items.count else {
            assertionFailure("Failed retrieve wallet item due to invalid index: \(index)")
            return nil
        }

        return items[index]
    }

    func loadItems() {
        switch itemsType {
        case .token:
            loadTokens()
        case .collectibles:
            loadCollectibles()
        }
    }

    private func loadTokens() {
        EthereumAPIClient.shared.getBalance(fetchedBalanceCompletion: { [weak self] balance, _ in

            self?.items = []

            if balance.floatValue > 0 {
                let etherToken = EtherToken(valueInWei: balance)
                self?.updateOrAdd(walletItem: etherToken, atFront: true)
                self?.delegate?.walletDatasourceDidReload()
            } // else, don't show ether balance.

            self?.delegate?.walletDatasourceDidReload()
            EthereumAPIClient.shared.getTokens { items, _ in
                self?.updateOrAdd(items: items)
                self?.delegate?.walletDatasourceDidReload()
            }
        })
    }

    private func updateOrAdd(items: [WalletItem]) {
        items.forEach { self.updateOrAdd(walletItem: $0) }
    }

    private func updateOrAdd(walletItem: WalletItem, atFront: Bool = false) {
        if let existingIndex = self.items.index(where: { $0.uniqueIdentifier == walletItem.uniqueIdentifier }) {
            self.items.remove(at: existingIndex)
            self.items.insert(walletItem, at: existingIndex)
        } else {
            if atFront && self.items.count > 0 {
                self.items.insert(walletItem, at: 0)
            } else {
                self.items.append(walletItem)
            }
        }
    }
    
    private func loadCollectibles() {
        EthereumAPIClient.shared.getCollectibles { [weak self] items, _ in
            self?.items = items
            self?.delegate?.walletDatasourceDidReload()
        }
    }
}
