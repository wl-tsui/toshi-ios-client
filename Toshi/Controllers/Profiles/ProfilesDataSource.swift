import Foundation
import UIKit
import TinyConstraints

protocol ProfileSelectionDelegate: class {
    func didSelectProfile(profile: TokenUser)
    func selectedProfileCountUpdated(to count: Int)
}

class ProfilesDataSource: NSObject {
    
    weak var selectionDelegate: ProfileSelectionDelegate?
    weak var tableView: UITableView?
    static let filteredProfilesKey = "Filtered_Profiles_Key"
    
    private let type: ProfilesViewControllerType
    private(set) var selectedProfiles = Set<TokenUser>()
    
    var isEmpty: Bool {
        let currentItemCount = mappings.numberOfItems(inSection: 0)
        return (currentItemCount == 0)
    }
    
    private(set) lazy var databaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()
        dbConnection.beginLongLivedReadTransaction()
        
        return dbConnection
    }()
    
    private(set) lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TokenUser.favoritesCollectionKey], view: ProfilesDataSource.filteredProfilesKey)
        mappings.setIsReversed(true, forGroup: TokenUser.favoritesCollectionKey)
        
        return mappings
    }()
    
    // MARK: - Initialization
    
    init(tableView: UITableView, type: ProfilesViewControllerType, selectionDelegate: ProfileSelectionDelegate) {
        self.type = type
        self.tableView = tableView
        self.selectionDelegate = selectionDelegate
        super.init()
        
        tableView.dataSource = self
        tableView.delegate = self

        tableView.estimatedRowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = Theme.viewBackgroundColor
        tableView.separatorStyle = .none
        
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.reuseIdentifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }
    
    // MARK: - Profile access

    private func profile(at indexPath: IndexPath) -> TokenUser? {
        var profile: TokenUser?
        
        databaseConnection.read { [weak self] transaction in
            guard let strongSelf = self,
                let dbExtension: YapDatabaseViewTransaction = transaction.extension(ProfilesDataSource.filteredProfilesKey) as? YapDatabaseViewTransaction,
                let data = dbExtension.object(at: indexPath, with: strongSelf.mappings) as? Data else { return }
            
            profile = TokenUser.user(with: data, shouldUpdate: false)
        }
        
        return profile
    }
    
    func updateProfileIfNeeded(at indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        
        IDAPIClient.shared.findContact(name: profile.address) { [weak self] _ in
            self?.tableView?.beginUpdates()
            self?.tableView?.reloadRows(at: [indexPath], with: .automatic)
            self?.tableView?.endUpdates()
        }
    }
    
    // MARK: - Table View Reloading
    
    func reloadData(completion: (() -> Void)? = nil) {
        if #available(iOS 11.0, *) {
            // Must perform batch updates on iOS 11 or you'll get super-wonky layout because of the headers.
            tableView?.performBatchUpdates({
                self.tableView?.reloadData()
            }, completion: { [weak self] _ in
                completion?()
                self?.tableView?.layoutIfNeeded()
            })
        } else {
            tableView?.reloadData()
            completion?()
        }
    }
    
    // MARK: - Database handling
    
    @objc private func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = databaseConnection.beginLongLivedReadTransaction()
        
        // swiftlint:disable:next force_cast
        let threadViewConnection = databaseConnection.ext(ProfilesDataSource.filteredProfilesKey) as! YapDatabaseViewConnection
        
        if !threadViewConnection.hasChanges(for: notifications) {
            databaseConnection.read { [weak self] transaction in
                self?.mappings.update(with: transaction)
            }
            
            return
        }
        
        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: mappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0
        
        guard isDatabaseChanged else { return }
        
        guard tableView?.superview != nil else {
            // The table view is not being displayed, we can do a full reload instead.
            tableView?.reloadData()
            
            return
        }
                
        tableView?.beginUpdates()
        
        for rowChange in yapDatabaseChanges.rowChanges {
            
            switch rowChange.type {
            case .delete:
                guard let indexPath = rowChange.indexPath else { continue }
                tableView?.deleteRows(at: [indexPath], with: .none)
            case .insert:
                guard let newIndexPath = rowChange.newIndexPath else { continue }
                updateProfileIfNeeded(at: newIndexPath)
                tableView?.insertRows(at: [newIndexPath], with: .none)
            case .move:
                guard let newIndexPath = rowChange.newIndexPath, let indexPath = rowChange.indexPath else { continue }
                tableView?.deleteRows(at: [indexPath], with: .none)
                tableView?.insertRows(at: [newIndexPath], with: .none)
            case .update:
                guard let indexPath = rowChange.indexPath else { continue }
                tableView?.reloadRows(at: [indexPath], with: .none)
            }
        }
        
        tableView?.endUpdates()
    }
}

extension ProfilesDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(mappings.numberOfSections())
    }
    
    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(mappings.numberOfItems(inSection: UInt(section)))
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ProfileCell.self, for: indexPath)
        
        guard let rowProfile = profile(at: indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return cell
        }
        
        cell.avatarPath = rowProfile.avatarPath
        cell.name = rowProfile.name
        cell.displayUsername = rowProfile.displayUsername
        
        if type == .newGroupChat {
            cell.selectionStyle = .none
            cell.isCheckmarkShowing = true
            cell.isCheckmarkChecked = selectedProfiles.contains(rowProfile)
        }
        
        return cell
    }
}

extension ProfilesDataSource: UITableViewDelegate {
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        
        switch type {
        case .favorites,
             .newChat:
            selectionDelegate?.didSelectProfile(profile: profile)
        case .newGroupChat:
            if selectedProfiles.contains(profile) {
                selectedProfiles.remove(profile)
            } else {
                selectedProfiles.insert(profile)
            }
            
            guard
                let header = tableView?.tableHeaderView as? ProfilesHeaderView,
                let selectedProfilesView = header.addedHeader else {
                    assertionFailure("Couldn't access header!")
                    return
            }
            
            selectedProfilesView.updateDisplay(with: selectedProfiles)
            selectionDelegate?.selectedProfileCountUpdated(to: selectedProfiles.count)
            
            self.reloadData()
        }
    }
}
