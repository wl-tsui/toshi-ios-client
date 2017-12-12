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

protocol SelectProfilesDelegate: class {

    /// Called when an unselected profile has been selected.
    func selected(profile: TokenUser)
    
    /// Called when a selected profile has been deselected.
    func deselected(profile: TokenUser)
}

class SelectProfilesTableViewDataSource: NSObject {
    
    private enum SelectProfilesSection: Int, CountableIntEnum {
        case
        selectedProfiles,
        unselectedProfiles
    }
    
    private var selectedProfiles = [TokenUser]()
    
    // TODO: Replace with something database backed
    private var unselectedProfiles = [TokenUser]()
    
    private weak var tableView: UITableView?
    private weak var selectionDelegate: SelectProfilesDelegate?
    
    init(with tableView: UITableView, selectionDelegate: SelectProfilesDelegate) {
        self.tableView = tableView
        self.selectionDelegate = selectionDelegate
        super.init()

        tableView.register(ProfileCell.self)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func profile(at indexPath: IndexPath) -> TokenUser {
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .selectedProfiles:
            return selectedProfiles[indexPath.row]
        case .unselectedProfiles:
            return unselectedProfiles[indexPath.row]
        }
    }
    
    // MARK: - Public API
    
    func update(with selectedProfiles: [TokenUser]) {
        self.selectedProfiles = selectedProfiles
        
        tableView?.reloadData()
    }
}

extension SelectProfilesTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SelectProfilesSection.AllCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SelectProfilesSection.forIndex(section) {
        case .selectedProfiles:
            return selectedProfiles.count
        case .unselectedProfiles:
            return unselectedProfiles.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ProfileCell.self, for: indexPath)
        cell.isCheckmarkShowing = true
        
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .selectedProfiles:
            cell.isCheckmarkChecked = true
        case .unselectedProfiles:
            cell.isCheckmarkChecked = false
        }
        
        let profile = self.profile(at: indexPath)
        cell.avatarPath = profile.avatarPath
        cell.name = profile.nameOrDisplayName
        cell.displayUsername = profile.displayUsername

        return cell
    }
}

extension SelectProfilesTableViewDataSource: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectionDelegate = selectionDelegate else { return }
        
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .selectedProfiles:
            let profile = selectedProfiles[indexPath.row]
            selectionDelegate.deselected(profile: profile)
        case .unselectedProfiles:
            let profile = unselectedProfiles[indexPath.row]
            selectionDelegate.selected(profile: profile)
        }
    }
}
