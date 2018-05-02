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

final class DappsListViewController: UIViewController {

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()

        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = true
        tableView.estimatedRowHeight = 50
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: .defaultMargin)

        tableView.delegate = self
        tableView.dataSource = self

        return tableView
    }()

    private lazy var dataSource: DappsDataSource = {
        let dataSource = DappsDataSource(mode: .allOrFiltered)
        dataSource.delegate = self

        return dataSource
    }()

    private var categoryId: Int?

    lazy var activeNetworkView: ActiveNetworkView = defaultActiveNetworkView()
    var activeNetworkObserver: NSObjectProtocol?

    init(categoryId: Int? = nil, name: String?) {
        super.init(nibName: nil, bundle: nil)

        title = name

        guard let id = categoryId else {
            dataSource.queryData.isSearching = true
            dataSource.fetchItems()
            return
        }
        
        self.categoryId = id
        dataSource.queryData.categoryId = id
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor
        setupActiveNetworkView()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.backgroundColor = Theme.navigationBarColor
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isMovingFromParentViewController else { return }
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    deinit {
        removeActiveNetworkObserver()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        BasicTableViewCell.register(in: tableView)

        tableView.edgesToSuperview(excluding: .bottom)
        tableView.bottomToTop(of: activeNetworkView)
    }
}

extension DappsListViewController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemAtIndexPath(indexPath), let dapp = item.dapp else { return }
        let controller = DappViewController(with: dapp, categoriesInfo: dataSource.categoriesInfo)
        Navigator.push(controller)
    }
}

extension DappsListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let dapp = dataSource.itemAtIndexPath(indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return UITableViewCell()
        }

        let cellData = TableCellData(title: dapp.displayTitle, leftImage: ImageAsset.collectible_placeholder, leftImagePath: dapp.itemIconPath, description: dapp.displayDetails)
        let configurator = CellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: configurator.cellIdentifier(for: cellData.components), for: indexPath) as? BasicTableViewCell else { return UITableViewCell() }

        configurator.configureCell(cell, with: cellData)
        cell.showSeparator(leftInset: 100, rightInset: .spacingx3)

        return cell
    }
}

extension DappsListViewController: DappsDataSourceDelegate {

    func dappsDataSourcedidReload(_ dataSource: DappsDataSource) {
        tableView.reloadData()
    }

    func dappsDataSourceDidEncounterError(_ dataSource: DappsDataSource, _ error: ToshiError) {
        // Default implementation shows error to the user, empty implementation suppresses that alert.
    }
}

extension DappsListViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}

extension DappsListViewController: ActiveNetworkDisplaying { /* mix-in */ }
