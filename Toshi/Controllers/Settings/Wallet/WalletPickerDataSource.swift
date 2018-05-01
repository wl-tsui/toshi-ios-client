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

final class WalletPickerDataSource: NSObject {

    private var tableView: UITableView
    private var wallets = [String]()

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        //Get wallets for real
        self.wallets = ["Wallet1", "Wallet2", "Wallet3", "Wallet4"]
    }
}

extension WalletPickerDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wallet = wallets[indexPath.row]

        let configurator = WalletPickerCellConfigurator()

        guard let cell = tableView.dequeueReusableCell(withIdentifier: WalletPickerCell.reuseIdentifier, for: indexPath) as? WalletPickerCell else { fatalError("Unexpected cell") }

        configurator.configureCell(cell, withWallet: wallet)

        return cell
    }
}

extension WalletPickerDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // select wallet
    }
}
