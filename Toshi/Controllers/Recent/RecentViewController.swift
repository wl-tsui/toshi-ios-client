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

final class RecentViewController: SweetTableController {

    private lazy var dataSource: ThreadsDataSource = {
        let dataSource = ThreadsDataSource(target: .chatsMainPage)
        dataSource.output = self

        return dataSource
    }()

    private var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    let idAPIClient = IDAPIClient.shared

    override init(style: UITableViewStyle) {
        super.init(style: style)

        title = dataSource.title

        loadViewIfNeeded()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

         let tableHeaderHeight = navigationController?.navigationBar.frame.height ?? 0

        tableView.delegate = self
        tableView.dataSource = self

        BasicTableViewCell.register(in: tableView)

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.showsVerticalScrollIndicator = true
        tableView.alwaysBounceVertical = true

        dataSource.output = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
        tabBarController?.tabBar.isHidden = false

        tableView.reloadData()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didPressCompose(_:)))
    }
    
    @objc private func didPressCompose(_ barButtonItem: UIBarButtonItem) {
        let datasource = ProfilesDataSource(type: .newChat)
        let profilesViewController = ProfilesNavigationController(rootViewController: ProfilesViewController(datasource: datasource, output: self))
        Navigator.presentModally(profilesViewController)
    }

    private func messagesRequestsCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let firstUnacceptedThread = dataSource.unacceptedThread(at: IndexPath(row: 0, section: 0)) else {
            return UITableViewCell(frame: .zero)
        }
        
        let cellConfigurator = CellConfigurator()
        var cellData: TableCellData
        var accessoryType: UITableViewCellAccessoryType

        let requestsTitle = "\(Localized.messages_requests_title) (\(dataSource.unacceptedThreadsCount))"
        let firstImage = firstUnacceptedThread.avatar()

        if let secondUnacceptedThread = dataSource.unacceptedThread(at: IndexPath(row: 1, section: 0)) {
            let secondImage = secondUnacceptedThread.avatar()
            cellData = TableCellData(title: requestsTitle, doubleImage: (firstImage: firstImage, secondImage: secondImage))
            accessoryType = .disclosureIndicator
        } else {
            cellData = TableCellData(title: requestsTitle, leftImage: firstImage)
            accessoryType = .none
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: cellData.components), for: indexPath)
        cellConfigurator.configureCell(cell, with: cellData)
        cell.accessoryType = accessoryType

        return cell
    }

    private func showThread(at indexPath: IndexPath) {
        guard let thread = dataSource.acceptedThread(at: indexPath.row, in: 0) else { return }
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

extension RecentViewController: SystemSharing { /* mix-in */ }

// MARK: - Table View Data Source

extension RecentViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard section < dataSource.sections.count else { return 0 }
        let chatsPageSection = dataSource.sections[section]

        return chatsPageSection.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell(frame: .zero)

        let section = dataSource.sections[indexPath.section]
        guard indexPath.row < section.items.count else { return UITableViewCell() }

        let item = section.items[indexPath.row]

        switch item {
        case .findPeople, .inviteFriend:
            let configurator = CellConfigurator()
            let cellData = TableCellData(title: item.title, leftImage: item.icon)
            cell = tableView.dequeueReusableCell(withIdentifier: configurator.cellIdentifier(for: cellData.components), for: indexPath)
            (cell as? BasicTableViewCell)?.titleTextField.textColor = Theme.tintColor
            configurator.configureCell(cell, with: cellData)
        case .messageRequests:
            cell = messagesRequestsCell(for: indexPath)
            cell.accessoryType = .disclosureIndicator
        case .chat:
            if let thread = dataSource.acceptedThread(at: indexPath.row, in: 0) {
                let threadCellConfigurator = ThreadCellConfigurator(thread: thread)
                let cellData = threadCellConfigurator.cellData
                cell = tableView.dequeueReusableCell(withIdentifier: AvatarTitleSubtitleDetailsBadgeCell.reuseIdentifier, for: indexPath)

                threadCellConfigurator.configureCell(cell, with: cellData)
                cell.accessoryType = .disclosureIndicator
            }
        }

        return cell
    }
}

// MARK: - Threads Data Source Output

extension RecentViewController: ThreadsDataSourceOutput {

    func threadsDataSourceDidLoad() {
        tableView.reloadData()
    }
}

// MARK: - Profiles List Completion Output

extension RecentViewController: ProfilesListCompletionOutput {

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

extension RecentViewController: UITableViewDelegate {

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
                let messagesRequestsViewController = MessagesRequestsViewController(style: .grouped)
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
