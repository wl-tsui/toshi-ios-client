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

final class ProfilesListViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        BasicTableViewCell.register(in: view)
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true
        view.estimatedRowHeight = .defaultCellHeight

        return view
    }()

    var type: String
    var name: String
    var datasource: SearchProfilesDataSource?

    init(query: String, name: String) {
        // Query is "type=type_title" string, we need just type_title for making request
        self.type = query.replacingOccurrences(of: "type=", with: "")
        self.name = name

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()

        title = name
        datasource = SearchProfilesDataSource(tableView: tableView)
        datasource?.delegate = self
        datasource?.search(type: type)
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)
    }
}

extension ProfilesListViewController: ProfilesDataSourceDelegate {

    func didSelectProfile(_ profile: Profile) {
        // WIP: Currently we need to deal with old type user till we replace it in all places

        guard let profileJson = profile.dictionary else { return }
        let oldTypeUser = TokenUser(json: profileJson)
        let profileController = ProfileViewController(profile: oldTypeUser)

        navigationController?.pushViewController(profileController, animated: true)
    }
}

extension ProfilesListViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}
