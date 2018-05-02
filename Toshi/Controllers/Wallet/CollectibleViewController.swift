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

import TinyConstraints
import UIKit

final class CollectibleViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.register(CollectibleCell.self)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    var collectibleContractAddress: String
    var datasource: CollectibleTokensDatasource

    lazy var activeNetworkView: ActiveNetworkView = defaultActiveNetworkView()
    var activeNetworkObserver: NSObjectProtocol?

    init(collectibleContractAddress: String) {
        self.collectibleContractAddress = collectibleContractAddress
        self.datasource = CollectibleTokensDatasource(collectibleContractAddress: collectibleContractAddress)

        super.init(nibName: nil, bundle: nil)

        datasource.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.viewBackgroundColor
        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)

        setupActiveNetworkView()

        let guide = layoutGuide()
        tableView.top(to: guide)
        tableView.left(to: guide)
        tableView.right(to: guide)
        tableView.bottomToTop(of: activeNetworkView)
    }

    deinit {
        removeActiveNetworkObserver()
    }
}

extension CollectibleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension CollectibleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.tokens?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let token = datasource.token(at: indexPath.row) else {
            assertionFailure("Can't find token at a given index path")
            return UITableViewCell()
        }

        let collectibleCellConfigurator = CollectibleCellConfigurator(collectible: token)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CollectibleCell.reuseIdentifier, for: indexPath)as? CollectibleCell else { return UITableViewCell() }

        collectibleCellConfigurator.configureCell(cell, dataSourceName: datasource.name)

        return cell
    }
}

extension CollectibleViewController: CollectibleTokensDatasourceDelegate {

    func collectibleDatasourceDidReload(_ datasource: CollectibleTokensDatasource) {
        tableView.reloadData()
        title = datasource.name
    }
}

extension CollectibleViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}

extension CollectibleViewController: ActiveNetworkDisplaying { /* mix-in */ }
