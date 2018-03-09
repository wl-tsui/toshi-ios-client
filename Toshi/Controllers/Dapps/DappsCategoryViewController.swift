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
import UIKit

final class DappsCategoryViewController: UITableViewController {

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var dataSource: DappsDataSource = {
        let dataSource = DappsDataSource(mode: .allOrFiltered)
        dataSource.delegate = self

        return dataSource
    }()

    private let categoryId: Int

    init(categoryId: Int, name: String?) {
        self.categoryId = categoryId

        super.init(nibName: nil, bundle: nil)

        dataSource.queryData.categoryId = categoryId
        title = name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor

        configureTableView()
        BasicTableViewCell.register(in: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isMovingFromParentViewController else { return }
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    private func configureTableView() {
        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = true
        tableView.contentInset.bottom = 60
        tableView.estimatedRowHeight = 50
        tableView.tableFooterView = UIView(frame: .zero)
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemAtIndexPath(indexPath), let dapp = item.dapp else { return }
        let controller = DappViewController(with: dapp, categoriesInfo: dataSource.categoriesInfo)
        Navigator.push(controller)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let dapp = dataSource.itemAtIndexPath(indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return UITableViewCell()
        }

        let cellData = TableCellData(title: dapp.displayTitle,
                                     subtitle: dapp.displayDetails,
                                     leftImagePath: dapp.itemIconPath)
        let cellConfigurator = CellConfigurator()
        let reuseIdentifier = cellConfigurator.cellIdentifier(for: cellData.components)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator

        cellConfigurator.configureCell(cell, with: cellData)

        return cell
    }
}

extension DappsCategoryViewController: DappsDataSourceDelegate {

    func dappsDataSourcedidReload(_ dataSource: DappsDataSource) {
        tableView.reloadData()
    }

    func dappsDataSourceDidEncounterError(_ dataSource: DappsDataSource, _ error: ToshiError) {

    }
}
