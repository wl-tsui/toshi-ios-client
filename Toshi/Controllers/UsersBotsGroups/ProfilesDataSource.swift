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
import Teapot

protocol ProfilesDataSourceDelegate: class {
    func didSelectProfile(_ profile: Profile)
    func didRequireOpenProfilesListFor(query: String, name: String)
}

extension ProfilesDataSourceDelegate {
    func didRequireOpenProfilesListFor(query: String, name: String) { }
}

final class ProfilesDataSource: NSObject {

    weak var delegate: ProfilesDataSourceDelegate?
    weak private var tableView: UITableView?
    private let defaultSectionHeaderHeight: CGFloat = 50

    private var sections: [ProfilesFrontPageSection] = []

    init(tableView: UITableView) {
        super.init()

        self.tableView = tableView
        self.tableView?.dataSource = self
        self.tableView?.delegate = self

        fetchUsersBotsGroupsFrontPage()
    }

    func fetchUsersBotsGroupsFrontPage() {
        searchProfilesFrontPage { [weak self] sections in
            guard let fetchedSections = sections else { return }

            self?.sections = fetchedSections
            self?.tableView?.reloadData()
        }
    }

    func profile(at indexPath: IndexPath) -> Profile? {
        let section = sections[indexPath.section]
        return section.profiles[indexPath.row]
    }
}

// MARK: - Mix-in extensions

extension ProfilesDataSource: ProfilesProviding { /* mix-in */ }

extension ProfilesDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = sections[section]
        return sectionData.profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionData = sections[indexPath.section]
        let profile = sectionData.profiles[indexPath.row]
        let cellData = TableCellData(title: profile.nameOrDisplayName, subtitle: profile.displayUsername, leftImagePath: profile.avatar, description: profile.description ?? "")
        let configurator = CellConfigurator()

        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else { fatalError("Unexpected cell") }

        let isLastCellInSection = (indexPath.row + 1) >= tableView.numberOfRows(inSection: indexPath.section)
        cell.showSeparator(forLastCellInSection: isLastCellInSection)
        configurator.configureCell(cell, with: cellData)

        return cell
    }
}

extension ProfilesDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionData = sections[section]

        let header = DappsSectionHeaderView(delegate: self)
        header.backgroundColor = Theme.viewBackgroundColor
        header.titleLabel.textColor = Theme.greyTextColor
        header.actionButton.setTitle(Localized.dapps_see_more_button_title, for: .normal)
        header.tag = section

        header.titleLabel.text = sectionData.name.uppercased()
        header.actionButton.isHidden = false

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return defaultSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let profile = profile(at: indexPath) else { return }
        delegate?.didSelectProfile(profile)
    }
}

extension ProfilesDataSource: DappsSectionHeaderViewDelegate {
    func dappsSectionHeaderViewDidReceiveActionButtonEvent(_ sectionHeaderView: DappsSectionHeaderView) {
        let sectionData = sections[sectionHeaderView.tag]
        delegate?.didRequireOpenProfilesListFor(query: sectionData.query, name: sectionData.name)
    }
}
