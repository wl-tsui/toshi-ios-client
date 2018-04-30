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
import SweetFoundation
import SweetUIKit

final class ChatsViewController: SweetTableController {

    private lazy var dataSource: ChatsDataSource = {
        let dataSource = ChatsDataSource(target: target, tableView: tableView)
        dataSource.output = self

        return dataSource
    }()

    private var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    let idAPIClient = IDAPIClient.shared

    private var target: ChatsDataSourceTarget

    init(style: UITableViewStyle, target: ChatsDataSourceTarget) {

        self.target = target
        super.init(style: style)

        title = dataSource.title

        loadViewIfNeeded()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self

        BasicTableViewCell.register(in: tableView)

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.showsVerticalScrollIndicator = true
        tableView.alwaysBounceVertical = true

        tableView.separatorInset.left = 80

        dataSource.output = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(target.prefersLargeTitle)
        tabBarController?.tabBar.isHidden = false

        tableView.reloadData()

        dismissIfNeeded(animated: false)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didPressCompose(_:)))
    }

    func dismissIfNeeded(animated: Bool = true) {
        guard target == .messageRequestsPage else { return }

        let isTopAndEmpty = Navigator.topNonModalViewController == self && dataSource.unacceptedThreadsCount == 0
        if isTopAndEmpty {
            navigationController?.popViewController(animated: animated)
        }
    }
    
    @objc private func didPressCompose(_ barButtonItem: UIBarButtonItem) {
        let newChatController = NewChatViewController()
        navigationController?.pushViewController(newChatController, animated: true)
    }

    private func threadToShow(at indexPath: IndexPath) -> TSThread? {
        switch target {
        case .chatsMainPage:
            return dataSource.acceptedThread(at: indexPath.row, in: 0)
        case .messageRequestsPage:
            return dataSource.unacceptedThread(at: indexPath)
        }
    }

    private func showThread(at indexPath: IndexPath) {
        guard let thread = threadToShow(at: indexPath) else { return }
        let chatViewController = ChatViewController(thread: thread)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    private func item(at indexPath: IndexPath) -> ChatsMainPageItem? {
        let chatsPageSection = dataSource.sections[indexPath.section]
        guard indexPath.row < chatsPageSection.items.count else { return nil }

        return chatsPageSection.items[indexPath.row]
    }

    func thread(withAddress address: String) -> TSThread? {
        return dataSource.thread(withAddress: address)
    }

    func thread(withIdentifier identifier: String) -> TSThread? {
        return dataSource.thread(withIdentifier: identifier)
    }
}

// MARK: - Mix-in extensions

extension ChatsViewController: SystemSharing { /* mix-in */ }

// MARK: - Threads Data Source Output

extension ChatsViewController: ChatsDataSourceOutput {

    func didRequireOpenThread(_ thread: TSThread) {
        let chatViewController = ChatViewController(thread: thread)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    func chatsDataSourceDidLoad() {
        tableView.reloadData()
        dismissIfNeeded()
    }
}

// MARK: - Profiles List Completion Output

extension ChatsViewController: ProfilesListCompletionOutput {

    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String]) {
        controller.dismiss(animated: true, completion: nil)

        guard let selectedProfileAddress = selectedProfilesIds.first else { return }

        let thread = ChatInteractor.getOrCreateThread(for: selectedProfileAddress)
        thread.isPendingAccept = false
        thread.save()

        DispatchQueue.main.async {
            Navigator.tabbarController?.displayMessage(forAddress: selectedProfileAddress)
            self.dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatsViewController: UITableViewDelegate {

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let item = item(at: indexPath) else { return }

        switch item {
        case .findPeople:
            let findUsersController = FindProfilesViewController()
            navigationController?.pushViewController(findUsersController, animated: true)
        case .messageRequests:
            if dataSource.hasUnacceptedThreads {
                let messagesRequestsViewController = ChatsViewController(style: .grouped, target: .messageRequestsPage)
                navigationController?.pushViewController(messagesRequestsViewController, animated: true)
            } else {
                showThread(at: indexPath)
            }
        case .chat:
            showThread(at: indexPath)
        case .inviteFriend:
            shareWithSystemSheet(item: Localized.sharing_action_item)
        }
    }

    /// WORKAROUND: For some reason the swift 4.1 compiler is convinced that `canEditRowAt` should be this
    /// method instead. Overridding and returning the documented default value to silence the warning.
    /// TODO: Revisit this when 4.2 comes out.
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool { return true }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let item = item(at: indexPath) else { return false }

        return item == .chat
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        guard let thread = dataSource.acceptedThread(at: indexPath.row, in: 0) else { return [] }

        let action = UITableViewRowAction(style: .destructive, title: Localized.thread_action_delete) { _, _ in
            ChatInteractor.deleteThread(thread)
        }

        let muteAction = UITableViewRowAction(style: .normal, title: thread.muteActionTitle) { _, _ in
            if thread.isMuted {
                ChatInteractor.unmuteThread(thread)
            } else {
                ChatInteractor.muteThread(thread)
            }
        }

        return [action, muteAction]
    }
}

extension ChatsViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return target.navTintColor }
    var navBarTintColor: UIColor? { return target.navBarTintColor }
    var navTitleColor: UIColor? { return target.navTitleColor }
    var navShadowImage: UIImage? { return target.navShadowImage }
}
