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

final class NewChatViewController: UIViewController {

    enum NewChatItem {
        case startGroup
        case inviteFriend

        var title: String {
            switch self {
            case .startGroup:
                return Localized.start_a_new_group
            case .inviteFriend:
                return Localized.recent_invite_a_friend
            }
        }

        var icon: UIImage {
            switch self {
            case .startGroup:
                return ImageAsset.group_icon
            case .inviteFriend:
                return ImageAsset.invite_friend
            }
        }
    }

    var scrollViewBottomInset: CGFloat = 0.0
    var scrollView: UIScrollView { return searchTableView }

    private let defaultTableViewBottomInset: CGFloat = -21

    private let newChatItems: [NewChatItem] = [.startGroup, .inviteFriend]
    private var dataSource: SearchProfilesDataSource?

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Theme.viewBackgroundColor
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.sectionFooterHeight = 0.0
        view.contentInset.bottom = defaultTableViewBottomInset
        view.scrollIndicatorInsets.bottom = defaultTableViewBottomInset
        view.estimatedRowHeight = 98
        view.alwaysBounceVertical = true
        view.separatorStyle = .none

        BasicTableViewCell.register(in: view)

        return view
    }()

    private lazy var searchHeaderView: PushedSearchHeaderView = {
        let view = PushedSearchHeaderView()
        view.searchPlaceholder = Localized.search_for_name_or_username
        view.rightButtonTitle = Localized.cancel_action_title
        view.delegate = self

        return view
    }()

    private lazy var searchTableView: SearchProfilesTableView = {
        let searchTableView = SearchProfilesTableView()
        searchTableView.profileTypeSelectionDelegate = self
        searchTableView.isHidden = true

        return searchTableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForKeyboardNotifications()

        dataSource = SearchProfilesDataSource(tableView: searchTableView)
        dataSource?.delegate = self
        addSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)

        preferLargeTitleIfPossible(false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        view.addSubview(searchHeaderView)
        view.addSubview(searchTableView)

        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true

        searchHeaderView.top(to: view)
        searchHeaderView.left(to: layoutGuide())
        searchHeaderView.right(to: layoutGuide())
        searchHeaderView.bottomAnchor.constraint(equalTo: layoutGuide().topAnchor, constant: PushedSearchHeaderView.headerHeight).isActive = true

        tableView.topToBottom(of: searchHeaderView)
        tableView.left(to: view)
        tableView.right(to: view)
        tableView.bottom(to: layoutGuide())

        searchTableView.edges(to: tableView)
    }
}

extension NewChatViewController: ProfileTypeSelectionDelegate {

    func searchProfilesTableViewDidChangeProfileType(_ tableView: SearchProfilesTableView) {
        dataSource?.search(type: searchTableView.selectedProfileType.typeString, text: searchHeaderView.searchTextField.text, searchDelay: SearchProfilesDataSource.defaultSearchRequestDelay)
    }
}

extension NewChatViewController: PushedSearchHeaderDelegate {
    func searchHeaderViewDidUpdateSearchText(_ headerView: PushedSearchHeaderView, _ searchText: String) {
        dataSource?.search(type: searchTableView.selectedProfileType.typeString, text: searchHeaderView.searchTextField.text)
    }

    func searchHeaderWillBeginEditing(_ headerView: PushedSearchHeaderView) {
        searchTableView.isHidden = false
    }

    func searchHeaderWillEndEditing(_ headerView: PushedSearchHeaderView) {
        searchTableView.isHidden = true
    }

    func searchHeaderDidReceiveRightButtonEvent(_ headerView: PushedSearchHeaderView) {
        // TODO: Cancel might be used later when search is being implemented, otherwise will be removed
    }

    func searchHeaderViewDidReceiveBackEvent(_ headerView: PushedSearchHeaderView) {
        navigationController?.popViewController(animated: true)
    }
}

extension NewChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newChatItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < newChatItems.count else { return UITableViewCell() }

        let item = newChatItems[indexPath.row]
        let cellData = TableCellData(title: item.title, leftImage: item.icon)

        let configurator = CellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: configurator.cellIdentifier(for: cellData.components), for: indexPath) as? BasicTableViewCell else { return UITableViewCell() }

        configurator.configureCell(cell, with: cellData)
        cell.titleTextField.textColor = Theme.tintColor

        cell.showSeparator(forLastCellInSection: item == .inviteFriend)

        return cell
    }
}

extension NewChatViewController: ProfilesDataSourceDelegate {

    func didSelectProfile(_ profile: Profile) {
        let profileController = ProfileViewController(profile: profile)
        navigationController?.pushViewController(profileController, animated: true)
    }
}

// MARK: - Mix-in extensions

extension NewChatViewController: SystemSharing { /* mix-in */ }

extension NewChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard indexPath.row < newChatItems.count else { return }

        let item = newChatItems[indexPath.row]

        switch item {
        case .inviteFriend:
            shareWithSystemSheet(item: Localized.sharing_action_item)
        case .startGroup:
            let groupChatSelection = ProfilesViewController(type: .newGroupChat)
            navigationController?.pushViewController(groupChatSelection, animated: true)
        }
    }
}

// MARK: - Keyboard Adjustable

extension NewChatViewController: KeyboardAdjustable {

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
