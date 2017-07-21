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

import UIKit
import SweetUIKit

class NetworkSettingsController: UIViewController {

    fileprivate lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
    }()

    fileprivate lazy var tableView: UITableView = {

        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsSelection = true
        view.dataSource = self
        view.delegate = self
        view.tableFooterView = UIView()

        view.register(UITableViewCell.self)

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Localized("Network")

        self.view.addSubview(self.tableView)
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.setupActivityIndicator()
    }

    func activeNetworkChanged(_ notification: Notification) {
        self.hideActivityIndicator()
        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(activeNetworkChanged(_:)), name: .SwitchedNetworkChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: .SwitchedNetworkChanged, object: nil)
    }
}

extension NetworkSettingsController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)

        let network = NetworkSwitcher.shared.availableNetworks[indexPath.row]
        cell.textLabel?.text = network.label
        cell.selectionStyle = .none

        let isActiveNetwork = network.rawValue == NetworkSwitcher.shared.activeNetwork.rawValue
        cell.accessoryType = isActiveNetwork ? .checkmark : .none

        return cell
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NetworkSwitcher.shared.availableNetworks.count
    }
}

extension NetworkSettingsController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let network = NetworkSwitcher.shared.availableNetworks[indexPath.row]

        guard network.rawValue != NetworkSwitcher.shared.activeNetwork.rawValue else { return }

        self.showActivityIndicator()
        NetworkSwitcher.shared.activateNetwork(network)
    }
}

extension NetworkSettingsController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}
