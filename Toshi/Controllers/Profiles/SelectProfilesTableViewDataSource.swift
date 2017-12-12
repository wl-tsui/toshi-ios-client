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
        
        var adjustedSection: Int {
            switch self {
            case .selectedProfiles:
                assertionFailure("This should be handled internally, not through adjustments")
                return 0
            default:
                return rawValue - 1
            }
        }
    }
    
    private(set) lazy var dataController = ProfilesDataController()
    
    private var selectedProfiles = [TokenUser]() {
        didSet {
            dataController.excludedProfilesIds = selectedProfiles.map { $0.address }
        }
    }
    
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
            let adjustedIndexPath = IndexPath(row: indexPath.row, section: SelectProfilesSection.unselectedProfiles.adjustedSection)
            guard let profile = dataController.profile(at: adjustedIndexPath) else {
                let errorNote = "Could not access profile at indexPath: \(indexPath), adjusted: \(adjustedIndexPath)"
                CrashlyticsLogger.log(errorNote)
                fatalError(errorNote)
            }
            
            return profile
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
            return dataController.numberOfItems(in: SelectProfilesSection.unselectedProfiles.adjustedSection)
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
        
        let profile = self.profile(at: indexPath)
        
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .selectedProfiles:
            selectionDelegate.deselected(profile: profile)
        case .unselectedProfiles:
            selectionDelegate.selected(profile: profile)
        }
    }
}
