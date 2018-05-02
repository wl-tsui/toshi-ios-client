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
import TinyConstraints

class AdvancedSettingsController: UIViewController {

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self)

        return tableView
    }()

    lazy var activeNetworkView: ActiveNetworkView = defaultActiveNetworkView()
    var activeNetworkObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActiveNetworkView()

        view.addSubview(tableView)
        tableView.edgesToSuperview(excluding: .bottom)
        tableView.bottomToTop(of: activeNetworkView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }

    deinit {
        removeActiveNetworkObserver()
    }
}

extension AdvancedSettingsController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)

        cell.textLabel?.font = Theme.preferredRegular()
        cell.textLabel?.text = Localized.settings_network_title
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return Localized.settings_advanced_network_change_warning
    }
}

extension AdvancedSettingsController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(NetworkSettingsController(), animated: true)
    }
}

extension AdvancedSettingsController: ActiveNetworkDisplaying { /* mix-in */ }
