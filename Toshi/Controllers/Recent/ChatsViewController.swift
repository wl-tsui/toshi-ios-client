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

    private lazy var dataSource: ThreadsDataSource = {
        let dataSource = ThreadsDataSource(target: target, tableView: tableView)
        dataSource.output = self

        return dataSource
    }()

    private var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    let idAPIClient = IDAPIClient.shared

    private var target: ThreadsDataSourceTarget = .chatsMainPage
    init(style: UITableViewStyle, target: ThreadsDataSourceTarget) {
        super.init(style: style)

        self.target = target

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

        if Navigator.topNonModalViewController == self && dataSource.unacceptedThreadsCount == 0 {
            navigationController?.popViewController(animated: animated)
        }
    }
    
    @objc private func didPressCompose(_ barButtonItem: UIBarButtonItem) {
        let datasource = ProfilesDataSource(type: .newChat)
        let profilesViewController = ProfilesNavigationController(rootViewController: ProfilesViewController(datasource: datasource, output: self))
        Navigator.presentModally(profilesViewController)
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

    func updateContactIfNeeded(at indexPath: IndexPath) {
        if let thread = dataSource.acceptedThread(at: indexPath.row, in: 0), let address = thread.contactIdentifier() {
            DLog("Updating contact info for address: \(address).")

            idAPIClient.retrieveUser(username: address) { contact in
                if let contact = contact {
                    DLog("Updated contact info for \(contact.username)")
                }
            }
        }
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

extension ChatsViewController: ThreadsDataSourceOutput {

    func didRequireOpenThread(_ thread: TSThread) {
        let chatViewController = ChatViewController(thread: thread)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    func threadsDataSourceDidLoad() {
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

        guard indexPath.section < dataSource.sections.count else { return }
        let chatsPageSection = dataSource.sections[indexPath.section]
        let item = chatsPageSection.items[indexPath.row]

        switch item {
        case .findPeople:
            // Present search controller
            break
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

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        guard indexPath.section < dataSource.sections.count else { return false }
        let chatsPageSection = dataSource.sections[indexPath.section]
        guard indexPath.row < chatsPageSection.items.count else { return false }
        let item = chatsPageSection.items[indexPath.row]

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
