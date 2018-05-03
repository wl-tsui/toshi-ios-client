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
import SweetUIKit

class NetworkSettingsController: UIViewController {

    lazy var activityIndicator: UIActivityIndicatorView = defaultActivityIndicator()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsSelection = true
        view.dataSource = self
        view.delegate = self
        view.tableFooterView = UIView()

        view.register(UITableViewCell.self)

        return view
    }()

    lazy var activeNetworkView: ActiveNetworkView = defaultActiveNetworkView()
    var activeNetworkObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized.settings_network_title

        setupActiveNetworkView()

        view.addSubview(tableView)
        tableView.edgesToSuperview(excluding: .bottom)
        tableView.bottomToTop(of: activeNetworkView)

        setupActivityIndicator()
    }

    deinit {
        removeActiveNetworkObserver()
    }
}

extension NetworkSettingsController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)

        let network = NetworkSwitcher.shared.availableNetworks[indexPath.row]
        cell.textLabel?.text = network.label
        cell.selectionStyle = .none

        let isActiveNetwork = (network.rawValue == NetworkSwitcher.shared.activeNetwork.rawValue)
        cell.accessoryType = isActiveNetwork ? .checkmark : .none

        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return NetworkSwitcher.shared.availableNetworks.count
    }
}

extension NetworkSettingsController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let network = NetworkSwitcher.shared.availableNetworks[indexPath.row]

        guard network.rawValue != NetworkSwitcher.shared.activeNetwork.rawValue else { return }

        showActivityIndicator()
        NetworkSwitcher.shared.activateNetwork(network)
    }
}

extension NetworkSettingsController: ActivityIndicating { /* mix-in */ }

extension NetworkSettingsController: ActiveNetworkDisplaying {
    func switchedNetworkChanged() {
        self.hideActivityIndicator()
        self.tableView.reloadData()

        updateActiveNetworkView()
    }
}
