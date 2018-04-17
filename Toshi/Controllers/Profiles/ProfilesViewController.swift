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

// MARK: - Profiles View Controller Type

public enum ProfilesViewControllerType {
    case newGroupChat
    case updateGroupChat
    
    var title: String {
        switch self {
        case .newGroupChat:
            return Localized.profiles_navigation_title_new_group_chat
        case .updateGroupChat:
            return Localized.profiles_navigation_title_update_group_chat
        }
    }
}

protocol ProfilesListCompletionOutput: class {
    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String])
}

// MARK: - Profiles View Controller

final class ProfilesViewController: UIViewController {

    let type: ProfilesViewControllerType
    private var searchBarText: String = ""

    private(set) var selectedProfiles = Set<TokenUser>()

    private(set) weak var output: ProfilesListCompletionOutput?

    var scrollViewBottomInset: CGFloat = 0.0

    var scrollView: UIScrollView { return tableView }

    var searchResults: [TokenUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)

        tableView.backgroundColor = Theme.viewBackgroundColor

        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = true
        tableView.tableFooterView = UIView(frame: .zero)

        BasicTableViewCell.register(in: tableView)
        
        return tableView
    }()

    // MARK: - Lazy Vars

    private lazy var profilesAddedToGroupHeader: ProfilesAddedToGroupHeader = {
        let profilesAddedToGroupHeader = ProfilesAddedToGroupHeader(margin: 16)

        return profilesAddedToGroupHeader
    }()

    private lazy var searchHeaderView: PushedSearchHeaderView = {
        let view = PushedSearchHeaderView()
        view.rightButtonTitle = Localized.done_action_title
        view.hidesBackButtonOnSearch = false
        view.searchPlaceholder = Localized.search_people_placeholder
        view.delegate = self
        view.setButtonEnabled(false)

        return view
    }()

    // MARK: - Initialization

    required public init(type: ProfilesViewControllerType, output: ProfilesListCompletionOutput? = nil) {

        self.type = type

        super.init(nibName: nil, bundle: nil)

        title = type.title
        self.output = output

        view.backgroundColor = Theme.viewBackgroundColor
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForKeyboardNotifications()

        definesPresentationContext = true

        updateHeaderWithSelections()

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }

        view.addSubview(searchHeaderView)
        view.addSubview(profilesAddedToGroupHeader)
        view.addSubview(tableView)

        searchHeaderView.top(to: view)
        searchHeaderView.left(to: layoutGuide())
        searchHeaderView.right(to: layoutGuide())
        searchHeaderView.bottomAnchor.constraint(equalTo: layoutGuide().topAnchor, constant: PushedSearchHeaderView.headerHeight).isActive = true

        profilesAddedToGroupHeader.topToBottom(of: searchHeaderView)
        profilesAddedToGroupHeader.left(to: view)
        profilesAddedToGroupHeader.right(to: view)
        profilesAddedToGroupHeader.height(54)

        tableView.topToBottom(of: profilesAddedToGroupHeader)
        tableView.left(to: view)
        tableView.right(to: view)
        tableView.bottom(to: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        searchHeaderView.becomeFirstResponder()

        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func updateHeaderWithSelections() {
        profilesAddedToGroupHeader.updateDisplay(with: selectedProfiles)
    }

    // MARK: - View Setup

    func isProfileSelected(_ profile: TokenUser) -> Bool {
        return selectedProfiles.contains(profile)
    }

    func updateSelection(with profile: TokenUser) {
        if selectedProfiles.contains(profile) {
            selectedProfiles.remove(profile)
        } else {
            selectedProfiles.insert(profile)
        }

        let validNumberOfProfiles = (type == .newGroupChat) ? 2 : 1
        searchHeaderView.setButtonEnabled(selectedProfiles.count >= validNumberOfProfiles)
    }

    private func didTapDone() {
        guard selectedProfiles.count > 0 else {
            assertionFailure("No selected profiles?!")

            return
        }

        let membersIdsArray = selectedProfiles.sorted { $0.username < $1.username }.map { $0.address }

        selectedProfiles.forEach { user in
            SessionManager.shared.contactsManager.refreshContact(user)
        }

        switch type {
        case .updateGroupChat:
            navigationController?.popViewController(animated: true)
            output?.didFinish(self, selectedProfilesIds: membersIdsArray)
        case .newGroupChat:
            guard let groupModel = TSGroupModel(title: "", memberIds: NSMutableArray(array: membersIdsArray), image: ImageAsset.avatar_edit_placeholder, groupId: nil) else { return }

            let viewModel = NewGroupViewModel(groupModel)
            let groupViewController = GroupViewController(viewModel, configurator: NewGroupConfigurator())
            navigationController?.pushViewController(groupViewController, animated: true)
        }
    }

    @objc private func reload(searchText: String) {
        searchBarText = searchText
        IDAPIClient.shared.searchContacts(name: searchText) { [weak self] users in
            if let searchBarText = self?.searchBarText, searchText == searchBarText {
                self?.searchResults = users
            }
        }
    }
}

// MARK: - Table View Delegate

extension ProfilesViewController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = searchResults.element(at: indexPath.row) else { return }

        updateSelection(with: item)
        updateHeaderWithSelections()

        tableView.reloadData()
    }
}

extension ProfilesViewController: UITableViewDataSource {

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let profile = searchResults.element(at: indexPath.row) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return UITableViewCell()
        }

        let tableData = TableCellData(title: profile.name,
                subtitle: profile.isApp ? profile.descriptionForSearch : profile.username,
                leftImagePath: profile.avatarPath,
                showCheckmark: true)
        let cellConfigurator = CellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: tableData.components), for: indexPath) as? BasicTableViewCell else {
            assertionFailure("Could not dequeue basic table view cell")
            return UITableViewCell()
        }

        cell.checkmarkView.checked = isProfileSelected(profile) ?? false
        cell.selectionStyle = .default
        cellConfigurator.configureCell(cell, with: tableData)

        return cell
    }
}

// MARK: - Pushed Search Header Delegate

extension ProfilesViewController: PushedSearchHeaderDelegate {
    func searchHeaderViewDidUpdateSearchText(_ headerView: PushedSearchHeaderView, _ searchText: String) {
        if searchText.isEmpty {
            searchResults = []
        }

        reload(searchText: searchText)
    }

    func searchHeaderWillBeginEditing(_ headerView: PushedSearchHeaderView) {

    }

    func searchHeaderWillEndEditing(_ headerView: PushedSearchHeaderView) {

    }

    func searchHeaderDidReceiveRightButtonEvent(_ headerView: PushedSearchHeaderView) {
        didTapDone()
    }
    
    func searchHeaderViewDidReceiveBackEvent(_ headerView: PushedSearchHeaderView) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Mix-in extensions

extension ProfilesViewController: SystemSharing { /* mix-in */ }

// MARK: - Keyboard Adjustable

extension ProfilesViewController: KeyboardAdjustable {

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }
}

extension ProfilesViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}
