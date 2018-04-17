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

struct SearchProfilesQueryData {

    var searchText: String?
    var limit: Int
    var offset: Int
    var type: String

    init(searchText: String? = nil, limit: Int = 100, offset: Int = 0, type: String = "user") {
        self.searchText = searchText
        self.limit = limit
        self.offset = offset
        self.type = type
    }
}

final class SearchProfilesDataSource: NSObject {

    static let defaultSearchRequestDelay: TimeInterval = 0.2

    weak var delegate: ProfilesDataSourceDelegate?
    private var queryData = SearchProfilesQueryData()
    private var profilesMap: [String: [Profile]] = [:]

    weak private var tableView: UITableView?

    private var reloadTimer: Timer?

    init(tableView: UITableView) {
        super.init()
        
        self.tableView = tableView
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
    }

    func search(type: String, text: String? = nil, searchDelay: TimeInterval = 0.0) {

        queryData.searchText = text
        queryData.type = type

        reloadTimer?.invalidate()
        reloadTimer = nil

        reloadTimer = Timer.scheduledTimer(withTimeInterval: searchDelay, repeats: false) { [weak self] _ in

            guard let strongSelf = self else { return }
            strongSelf.searchProfilesOfType(type: strongSelf.queryData.type, searchText: strongSelf.queryData.searchText, completion: { [weak self] profiles, type in
                guard let strongSelf = self else { return }

                strongSelf.profilesMap[type] = profiles

                // No need to reload if current profiles type selection has changed while the response was received
                guard strongSelf.queryData.type == type else { return }
                strongSelf.tableView?.reloadData()
            })
        }
    }

    func clearResults() {
        profilesMap = [:]
        tableView?.reloadData()
    }

    private func profile(at indexPath: IndexPath) -> Profile? {
        guard let typeProfiles = profilesMap[queryData.type] else { fatalError() }
        return typeProfiles[indexPath.row]
    }
}

// MARK: - Mix-in extensions

extension SearchProfilesDataSource: ProfilesProviding { /* mix-in */ }

extension SearchProfilesDataSource: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let typeProfiles = profilesMap[queryData.type] else { return 0 }
        return typeProfiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let typeProfiles = profilesMap[queryData.type] else { fatalError() }
        let profile = typeProfiles[indexPath.row]

        let cellData = TableCellData(title: (profile.name ?? "").isEmpty ? profile.username : profile.name, subtitle: profile.displayUsername, leftImagePath: profile.avatar, description: profile.description)
        let configurator = CellConfigurator()

        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? BasicTableViewCell else { fatalError("Unexpected cell") }

        configurator.configureCell(cell, with: cellData)
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

extension SearchProfilesDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        delegate?.didSelectProfile(profile)
    }
}
