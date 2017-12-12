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

import TinyConstraints
import UIKit

// A view controller to allow selection of an arbitrary number of profiles.
class SelectProfilesViewController: UIViewController {
    
    var selectedProfiles = [TokenUser]() {
        didSet {
            updateCollectionAndTableViews()
        }
    }
    
    private lazy var collectionViewLayout: UICollectionViewLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        let minSpacing: CGFloat = 4
        flowLayout.minimumLineSpacing = minSpacing
        flowLayout.minimumInteritemSpacing = minSpacing
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        return collectionView
    }()

    private lazy var collectionViewDataSource = SelectProfilesCollectionViewDataSource(with: collectionView, searchDelegate: self)

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        return tableView
    }()
    
    private lazy var tableViewDataSource = SelectProfilesTableViewDataSource(with: tableView, selectionDelegate: self)

    private lazy var doneButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        return barButton
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupTableView()
        
        edgesForExtendedLayout = []
        
        navigationItem.rightBarButtonItem = doneButton
    }
    
    // MARK: - View Setup
    
    private func setupCollectionView() {
        view.addSubview(collectionView)

        collectionView.edgesToSuperview(excluding: .bottom)
        collectionView.backgroundColor = Theme.inputFieldBackgroundColor
        collectionView.height(min: 44, max: CGFloat.greatestFiniteMagnitude, priority: .defaultHigh, isActive: true)
        collectionViewDataSource.update(with: selectedProfiles)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)

        tableView.edgesToSuperview(excluding: .top)
        tableView.topToBottom(of: collectionView)
        tableViewDataSource.update(with: selectedProfiles)
    }
    
    // MARK: - Updating
    
    private func updateCollectionAndTableViews() {
        tableViewDataSource.update(with: selectedProfiles)
        collectionViewDataSource.update(with: selectedProfiles)
    }
    
    // MARK: - Action targets
    
    @objc private func doneButtonTapped() {
        DLog("Done!")
    }
}

// MARK: - Profile Search Delegate

extension SelectProfilesViewController: ProfileSearchDelegate {
    
    func enteredText(_ text: String?) {
        DLog("Text is now: \(String(describing: text))")
    }
}

// MARK: - Select Profiles Delegate

extension SelectProfilesViewController: SelectProfilesDelegate {
    
    func selected(profile: TokenUser) {
        guard !selectedProfiles.contains(profile) else {
            // Profile is already added.
            return
        }
        
        selectedProfiles.append(profile)
        updateCollectionAndTableViews()
    }
    
    func deselected(profile: TokenUser) {
        guard let indexToRemove = selectedProfiles.index(of: profile) else {
            // Nothing to remove.
            return
        }
        
        selectedProfiles.remove(at: indexToRemove)
        updateCollectionAndTableViews()
    }
}
