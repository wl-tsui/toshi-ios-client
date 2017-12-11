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

// MARK: - Profiles View Controller Type

public enum ProfilesViewControllerType {
    case favorites
    case newChat
    case newGroupChat
    
    var title: String {
        switch self {
        case .favorites:
            return Localized("profiles_navigation_title_favorites")
        case .newChat:
            return Localized("profiles_navigation_title_new_chat")
        case .newGroupChat:
            return Localized("profiles_navigation_title_new_group_chat")
        }
    }
}

// MARK: - Profiles View Controller

final class ProfilesViewController: UITableViewController, Emptiable {
    
    let type: ProfilesViewControllerType
    
    var scrollViewBottomInset: CGFloat = 0
    let emptyView = EmptyView(title: Localized("favorites_empty_title"), description: Localized("favorites_empty_description"), buttonTitle: Localized("invite_friends_action_title"))
    
    var scrollView: UIScrollView {
        return tableView
    }
    
    private var filtering: YapDatabaseViewFiltering {
        let searchText = searchController.searchBar.text?.lowercased() ?? ""
        let filteringBlock: YapDatabaseViewFilteringWithObjectBlock = { transaction, group, colelction, key, object in
            guard searchText.length > 0 else { return true }
            guard let data = object as? Data, let deserialised = (try? JSONSerialization.jsonObject(with: data, options: [])), var json = deserialised as? [String: Any], let username = json[TokenUser.Constants.username] as? String else { return false }
            
            return username.lowercased().contains(searchText)
        }
        
        return YapDatabaseViewFiltering.withObjectBlock(filteringBlock)
    }
    
    // MARK: - Lazy Vars
    
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel(_:)))
    private lazy var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone(_:)))
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(_:)))
    private lazy var filteredView = YapDatabaseFilteredView(parentViewName: TokenUser.viewExtensionName, filtering: filtering)
    
    private lazy var databaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()
        
        return dbConnection
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.delegate = self
        controller.searchBar.barTintColor = Theme.viewBackgroundColor
        controller.searchBar.tintColor = Theme.tintColor
        controller.searchBar.placeholder = "Search by username"
        
        guard #available(iOS 11.0, *) else {
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.backgroundColor = Theme.viewBackgroundColor
            controller.searchBar.layer.borderWidth = .lineHeight
            controller.searchBar.layer.borderColor = Theme.borderColor.cgColor
            
            return controller
        }
        
        let searchField = controller.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor
        
        return controller
    }()
    
    lazy var dataSource: ProfilesDataSource = {
        let dataSource = ProfilesDataSource(tableView: tableView, type: type, selectionDelegate: self)
        
        return dataSource
    }()
    
    // MARK: - Initialization
    
    required public init(type: ProfilesViewControllerType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        
        title = type.title
        
        setupForCurrentUserNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userCreated(_:)), name: .userCreated, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableHeader()
        setupNavigationBarButtons()

        definesPresentationContext = true
        
        let appearance = UIButton.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        appearance.setTitleColor(Theme.greyTextColor, for: .normal)
        
        setupEmptyView()
        displayContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        preferLargeTitleIfPossible(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollViewBottomInset = tableView.contentInset.bottom
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in searchController.searchBar.subviews {
            view.clipsToBounds = false
        }
        searchController.searchBar.superview?.clipsToBounds = false
    }
    
    // MARK: - View Setup

    private func setupTableHeader() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            tableView.tableHeaderView = ProfilesHeaderView(type: type, delegate: self)
        } else {
            tableView.tableHeaderView = ProfilesHeaderView(with: searchController.searchBar, type: type, delegate: self)
            tableView.layoutIfNeeded()
        }
    }
    
    private func setupEmptyView() {
        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide(), insets: UIEdgeInsets(top: tableView.tableHeaderView?.frame.height ?? 0, left: 0, bottom: 0, right: 0))
        showOrHideEmptyState()
    }
    
    private func setupNavigationBarButtons() {
        switch type {
        case .newChat:
            navigationItem.leftBarButtonItem = cancelButton
        case .favorites:
            navigationItem.rightBarButtonItem = addButton
        case .newGroupChat:
            navigationItem.rightBarButtonItem = doneButton
            doneButton.isEnabled = false
        }
    }
    
    // MARK: - Notification setup
    
    @objc private func userCreated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setupForCurrentUserNotifications()
        }
    }
    
    private func setupForCurrentUserNotifications() {
        guard TokenUser.current != nil else { return }
        
        registerTokenContactsDatabaseView()
        
        dataSource.databaseConnection.asyncRead { [weak self] transaction in
            self?.dataSource.mappings.update(with: transaction)
        }
    }

    // MARK: - Database handling
    
    private func contactSorting() -> YapDatabaseViewSorting {
        let viewSorting = YapDatabaseViewSorting.withObjectBlock { (_, _, _, _, object1, _, _, object2) -> ComparisonResult in
            if let data1 = object1 as? Data, let data2 = object2 as? Data,
                let contact1 = TokenUser.user(with: data1),
                let contact2 = TokenUser.user(with: data2) {
                
                return contact1.username.compare(contact2.username)
            }
            
            return .orderedAscending
        }
        
        return viewSorting
    }
    
    @discardableResult
    private func registerTokenContactsDatabaseView() -> Bool {
        guard let database = Yap.sharedInstance.database else { fatalError("couldn't instantiate the database") }
        // Check if it's already registered.
        guard database.registeredExtension(TokenUser.viewExtensionName) == nil else { return true }
        
        let viewGrouping = YapDatabaseViewGrouping.withObjectBlock { (_, _, _, object) -> String? in
            if (object as? Data) != nil {
                return TokenUser.favoritesCollectionKey
            }
            
            return nil
        }
        
        let viewSorting = contactSorting()
        
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: Set([TokenUser.favoritesCollectionKey]))
        
        let databaseView = YapDatabaseAutoView(grouping: viewGrouping, sorting: viewSorting, versionTag: "1", options: options)
        
        let mainViewIsRegistered: Bool = database.register(databaseView, withName: TokenUser.viewExtensionName)
        let filteredViewIsRegistered = database.register(filteredView, withName: ProfilesDataSource.filteredProfilesKey)
        
        return mainViewIsRegistered && filteredViewIsRegistered
    }
    
    private func displayContacts() {
        dataSource.reloadData { [weak self] in
            self?.showOrHideEmptyState()
        }
    }
    
    // MARK: - Action Handling
    
    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        let shareController = UIActivityViewController(activityItems: [Localized("sharing_action_item")], applicationActivities: [])
        Navigator.presentModally(shareController)
    }
    
    private func showOrHideEmptyState() {
        emptyView.isHidden = (searchController.isActive || !dataSource.isEmpty)
    }
    
    @objc private func didTapCancel(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapAdd(_ button: UIBarButtonItem) {
        let addContactSheet = UIAlertController(title: Localized("favorites_add_title"), message: nil, preferredStyle: .actionSheet)
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_add_by_username"), style: .default, handler: { _ in
            self.searchController.searchBar.becomeFirstResponder()
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("invite_friends_action_title"), style: .default, handler: { _ in
            let shareController = UIActivityViewController(activityItems: ["Get Toshi, available for iOS and Android! (https://www.toshi.org)"], applicationActivities: [])
            
            Navigator.presentModally(shareController)
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_scan_code"), style: .default, handler: { _ in
            guard let tabBarController = self.tabBarController as? TabBarController else { return }
            tabBarController.switch(to: .scanner)
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))
        
        addContactSheet.view.tintColor = Theme.tintColor
        present(addContactSheet, animated: true)
    }
    
    @objc private func didTapDone(_ button: UIBarButtonItem) {
        guard type == .newGroupChat else {
            assertionFailure("Done button is only set up to handle creating a new group!")
            
            return
        }
        
        guard dataSource.selectedProfiles.count > 0 else {
            assertionFailure("No selected profiles?!")
            
            return
        }
        
        //TODO: Push to group chat settings screen
        let usernames = dataSource.selectedProfiles.map { $0.name }.joined(separator: "\n")
        let alert = UIAlertController(title: "Coming soon!", message: "Group chat is under development. Soon you can talk to:\n\(usernames)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
}

// MARK: - Profile Selection Delegate

extension ProfilesViewController: ProfileSelectionDelegate {
    
    func didSelectProfile(profile: TokenUser) {
        searchController.searchBar.resignFirstResponder()
        
        if type == .newChat {
            ChatInteractor.getOrCreateThread(for: profile.address)
            
            DispatchQueue.main.async {
                Navigator.tabbarController?.displayMessage(forAddress: profile.address)
                self.dismiss(animated: true)
            }
        } else {
            navigationController?.pushViewController(ProfileViewController(profile: profile), animated: true)
            UserDefaultsWrapper.selectedContact = profile.address
        }
    }

    func selectedProfileCountUpdated(to count: Int) {
        // Groups must consist of at least two other members
        if count > 1 {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
    }
}

// MARK: - Search Bar Delegate

extension ProfilesViewController: UISearchBarDelegate {
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        if type != .newChat {
            displayContacts()
        }
    }
}

// MARK: - Search Results Updating

extension ProfilesViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        
        databaseConnection.readWrite { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let filterTransaction = transaction.ext(ProfilesDataSource.filteredProfilesKey) as? YapDatabaseFilteredViewTransaction else { return }
            
            let tag = Date().timeIntervalSinceReferenceDate
            filterTransaction.setFiltering(strongSelf.filtering, versionTag: String(describing: tag))
        }
    }
}

// MARK: - Profiles Add Group Header Delegate

extension ProfilesViewController: ProfilesAddGroupHeaderDelegate {
    
    func newGroup() {
        let groupChatSelection = ProfilesViewController(type: .newGroupChat)
        navigationController?.pushViewController(groupChatSelection, animated: true)
    }
}
