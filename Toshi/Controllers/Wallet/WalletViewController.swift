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

final class WalletViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    private lazy var tableHeaderView: UIView = {
        let walletItemTitles = [Localized("wallet_tokens"), Localized("wallet_collectibles")]
        let headerView = SegmentedHeaderView(segmentNames: walletItemTitles, delegate: self)
        headerView.backgroundColor = Theme.viewBackgroundColor

        return headerView
    }()

    private lazy var datasource = WalletDatasource(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized("wallet_controller_title")
        view.backgroundColor = Theme.lightGrayBackgroundColor

        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)

        let headerView = WalletTableHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 110))

        let height = headerView.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height
        var headerFrame = headerView.frame
        headerFrame.size.height = height
        headerView.frame = headerFrame

        tableView.tableHeaderView = headerView
    }
}

extension WalletViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.numberOfItems
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let walletItem = datasource.item(at: indexPath.row) else {
            assertionFailure("Can;t retireve item at index: \(indexPath.row)")
            return UITableViewCell()
        }

        let cellData = TableCellData(title: walletItem.title, subtitle: walletItem.subtitle)
        let configurator = CellConfigurator()
        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else {
            assertionFailure("Can't dequeue basic cell on wallet view controller for given reuse identifier: \(reuseIdentifier)")
            return UITableViewCell()
        }

        configurator.configureCell(cell, with: cellData)

        return cell
    }
}

extension WalletViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selcted tow at indexpath")
    }
}

extension WalletViewController: SegmentedHeaderDelegate {

    func segmentedHeader(_: SegmentedHeaderView, didSelectSegmentAt index: Int) {
        guard let itemType = WalletItemType(rawValue: index) else {
            assertionFailure("Can't create wallet item with given selected index: \(index)")
            return
        }

        datasource.itemsType = itemType
    }
}

extension WalletViewController: WalletDatasourceDelegate {

    func walletDatasourceDidReload() {
        tableView.reloadData()
    }
}
