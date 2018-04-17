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
import TinyConstraints

final class FindProfilesViewController: UIViewController {

    var scrollViewBottomInset: CGFloat = 0.0
    var scrollView: UIScrollView { return searchTableView }

    private var mainDataSource: ProfilesDataSource?
    private var searchDataSource: SearchProfilesDataSource?

    private let defaultTableViewBottomInset: CGFloat = -21

    private lazy var searchHeaderView: PushedSearchHeaderView = {
        let view = PushedSearchHeaderView()
        view.searchPlaceholder = Localized.search_people_placeholder
        view.rightButtonTitle = Localized.cancel_action_title
        view.delegate = self

        return view
    }()

    private lazy var mainTableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Theme.viewBackgroundColor
        BasicTableViewCell.register(in: view)
        view.sectionFooterHeight = 0.0
        view.contentInset.bottom = defaultTableViewBottomInset
        view.scrollIndicatorInsets.bottom = defaultTableViewBottomInset
        view.estimatedRowHeight = 98
        view.alwaysBounceVertical = true
        view.separatorStyle = .none

        return view
    }()

    private lazy var searchTableView: SearchProfilesTableView = {
        let searchTableView = SearchProfilesTableView()
        searchTableView.isHidden = true
        searchTableView.profileTypeSelectionDelegate = self

        return searchTableView
    }()

    @objc private func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForKeyboardNotifications()

        mainDataSource = ProfilesDataSource(tableView: mainTableView)
        mainDataSource?.delegate = self
        searchDataSource = SearchProfilesDataSource(tableView: searchTableView)
        searchDataSource?.delegate = self

        addSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(searchHeaderView)
        view.addSubview(mainTableView)
        view.addSubview(searchTableView)

        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true

        searchHeaderView.top(to: view)
        searchHeaderView.left(to: layoutGuide())
        searchHeaderView.right(to: layoutGuide())
        searchHeaderView.bottomAnchor.constraint(equalTo: layoutGuide().topAnchor, constant: PushedSearchHeaderView.headerHeight).isActive = true

        mainTableView.topToBottom(of: searchHeaderView)
        mainTableView.left(to: view)
        mainTableView.right(to: view)
        mainTableView.bottom(to: layoutGuide())

        searchTableView.edges(to: mainTableView)
    }
}

extension FindProfilesViewController: PushedSearchHeaderDelegate {
    func searchHeaderDidReceiveRightButtonEvent(_ headerView: PushedSearchHeaderView) {
        searchDataSource?.clearResults()
    }

    func searchHeaderWillBeginEditing(_ headerView: PushedSearchHeaderView) {
        searchTableView.isHidden = false
    }

    func searchHeaderWillEndEditing(_ headerView: PushedSearchHeaderView) {
        searchTableView.isHidden = true
    }

    func searchHeaderViewDidUpdateSearchText(_ headerView: PushedSearchHeaderView, _ searchText: String) {
        searchDataSource?.search(type: searchTableView.selectedProfileType.typeString, text: searchText, searchDelay: SearchProfilesDataSource.defaultSearchRequestDelay)
    }

    func searchHeaderViewDidReceiveBackEvent(_ headerView: PushedSearchHeaderView) {
        navigationController?.popViewController(animated: true)
    }
}

extension FindProfilesViewController: ProfileTypeSelectionDelegate {

    func searchProfilesTableViewDidChangeProfileType(_ tableView: SearchProfilesTableView) {
        searchDataSource?.search(type: searchTableView.selectedProfileType.typeString, text: searchHeaderView.searchTextField.text)
    }
}

extension FindProfilesViewController: ProfilesDataSourceDelegate {

    func didSelectProfile(_ profile: Profile) {
        // WIP: Currently we need to deal with old type user till we replace it in all places

        guard let profileJson = profile.dictionary else { return }
        let oldTypeUser = TokenUser(json: profileJson)
        let profileController = ProfileViewController(profile: oldTypeUser)

        navigationController?.pushViewController(profileController, animated: true)
    }

    func didRequireOpenProfilesListFor(query: String, name: String) {
        let controller = ProfilesListViewController(query: query, name: name)
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Keyboard Adjustable

extension FindProfilesViewController: KeyboardAdjustable {

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
