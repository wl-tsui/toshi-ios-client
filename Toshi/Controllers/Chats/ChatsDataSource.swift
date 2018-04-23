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

enum ChatsDataSourceTarget {
    case chatsMainPage
    case messageRequestsPage

    var title: String {
        switch self {
        case .chatsMainPage:
            return Localized.tab_bar_title_chats
        case .messageRequestsPage:
            return Localized.messages_requests_title
        }
    }

    var navTintColor: UIColor {
        switch self {
        case .chatsMainPage:
            return Theme.lightTextColor
        case .messageRequestsPage:
            return Theme.tintColor
        }
    }

    var navBarTintColor: UIColor {
        switch self {
        case .chatsMainPage:
            return Theme.tintColor
        case .messageRequestsPage:
            return Theme.navigationBarColor
        }
    }

    var navTitleColor: UIColor {
        switch self {
        case .chatsMainPage:
            return Theme.lightTextColor
        case .messageRequestsPage:
            return Theme.darkTextColor
        }
    }

    var navShadowImage: UIImage? {
        switch self {
        case .chatsMainPage:
            return UIImage()
        case .messageRequestsPage:
            return nil
        }
    }

    var prefersLargeTitle: Bool {
        return self == .messageRequestsPage
    }
}

enum ChatsSectionType {
    case findPeople
    case messageRequests
    case chats
}

struct ChatsMainPageSection {

    var type: ChatsSectionType = .findPeople
    var items: [ChatsMainPageItem] = []
}

enum ChatsMainPageItem {
    case findPeople
    case messageRequests
    case chat
    case inviteFriend

    var title: String? {
        switch self {
        case .findPeople:
            return Localized.recent_find_people_title
        case .inviteFriend:
            return Localized.recent_invite_a_friend
        default:
            return nil
        }
    }

    var icon: UIImage? {
        switch self {
        case .inviteFriend:
            return ImageAsset.invite_friend
        case .findPeople:
            return ImageAsset.find_people
        default:
            return nil
        }
    }
}

protocol ChatsDataSourceOutput: class {
    func chatsDataSourceDidLoad()
    func didRequireOpenThread(_ thread: TSThread)
}

final class ChatsDataSource: NSObject {

    private var viewModel: RecentViewModel
    private var target: ChatsDataSourceTarget

    private let mainPageSectionsCount = 2
    private let mainPageWithRequestsSectionsCount = 3
    private let messageRequestsPageSectionsCount = 1

    var sections: [ChatsMainPageSection] = []

    var hasUnacceptedThreads: Bool {
        return unacceptedThreadsCount > 0
    }

    var unacceptedThreadsCount: Int {
        return Int(viewModel.unacceptedThreadsMappings.numberOfItems(inSection: UInt(0)))
    }

    var acceptedThreadsCount: Int {
        return Int(viewModel.acceptedThreadsMappings.numberOfItems(inSection: UInt(0)))
    }

    // If the datasource serves MessageRequestsController, there is always 1 section only
    var numberOfSections: Int {
        switch target {
        case .chatsMainPage:
            return hasUnacceptedThreads ? mainPageWithRequestsSectionsCount : mainPageSectionsCount
        case .messageRequestsPage:
            return messageRequestsPageSectionsCount
        }
    }

    var title: String {
        return target.title
    }

    weak var output: ChatsDataSourceOutput?

    weak private var tableView: UITableView?

    init(target: ChatsDataSourceTarget, tableView: UITableView?) {
        viewModel = RecentViewModel()
        self.target = target
        self.tableView = tableView

        super.init()

        self.tableView?.dataSource = self

        if TokenUser.current != nil {
            viewModel.setupForCurrentSession()
            loadMessages()
            registerNotifications()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(chatDBCreated(_:)), name: .ChatDatabaseCreated, object: nil)
        }
    }

    @objc private func chatDBCreated(_ notification: Notification) {
        viewModel.setupForCurrentSession()
        loadMessages()
        registerNotifications()
    }

    @objc func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = viewModel.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // swiftlint:disable:next force_cast
        let threadViewConnection = viewModel.uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection

        let hasChangesForCurrentView = threadViewConnection.hasChanges(for: notifications)
        guard hasChangesForCurrentView else {
            viewModel.uiDatabaseConnection.read { [weak self] transaction in
                self?.viewModel.acceptedThreadsMappings.update(with: transaction)
                self?.viewModel.unacceptedThreadsMappings.update(with: transaction)
                self?.viewModel.allThreadsMappings.update(with: transaction)
            }

            return
        }

        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: viewModel.allThreadsMappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0

        guard isDatabaseChanged else { return }
        
        if let insertedRow = yapDatabaseChanges.rowChanges.first(where: { $0.type == .insert }) {

            if let newIndexPath = insertedRow.newIndexPath {
                processNewThread(at: newIndexPath)
            }
        } else if let updatedRow = yapDatabaseChanges.rowChanges.first(where: { $0.type == .update }) {

            if let indexPath = updatedRow.indexPath {
                processUpdateThread(at: indexPath)
            }
        }

        loadMessages()
        output?.chatsDataSourceDidLoad()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func unacceptedThread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let dbExtension = transaction.extension(RecentViewModel.unacceptedThreadsFilteringKey) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: strongSelf.viewModel.unacceptedThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func thread(withAddress address: String) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.contactIdentifier() == address {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }

    func thread(withIdentifier identifier: String) -> TSThread? {
        var thread: TSThread?

       viewModel.uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.uniqueId == identifier {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }

    func acceptedThread(at index: Int, in section: Int) -> TSThread? {
        var thread: TSThread?

        viewModel.uiDatabaseConnection.read { [weak self] transaction in
            guard let strongSelf = self else { return }
            guard let dbExtension = transaction.extension(RecentViewModel.acceptedThreadsFilteringKey) as? YapDatabaseViewTransaction else { return }
            let translatedIndexPath = IndexPath(row: index, section: section)
            guard let object = dbExtension.object(at: translatedIndexPath, with: strongSelf.viewModel.acceptedThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func processNewThread(at indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath) {
            updateNewThreadRecepientsIfNeeded(thread)
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

         viewModel.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: self.viewModel.allThreadsMappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func updateNewThreadRecepientsIfNeeded(_ thread: TSThread) {
        DispatchQueue.main.async {
            if let contactId = thread.contactIdentifier() {
                guard SessionManager.shared.contactsManager.tokenContact(forAddress: contactId) == nil else { return }

                let contactsIds = SessionManager.shared.contactsManager.tokenContacts.map { $0.address }

                IDAPIClient.shared.findContact(name: contactId, completion: { foundUser in

                    guard let user = foundUser else { return }

                    AvatarManager.shared.downloadAvatar(for: user.avatarPath)

                    if !contactsIds.contains(contactId) {
                        IDAPIClient.shared.updateContact(with: contactId)
                        TSThread.saveRecipient(with: contactId)
                    }
                })
            } else {
                thread.updateGroupMembers()
            }
        }
    }
    
    private func processUpdateThread(at indexPath: IndexPath) {
        if let thread = self.acceptedThread(at: indexPath.row, in: 0) {

            if let topChatViewController = Navigator.topViewController as? ChatViewController {
                topChatViewController.updateThread(thread)
            }

            if thread.isGroupThread() && ProfileManager.shared().isThread(inProfileWhitelist: thread) == false {
                ProfileManager.shared().addThread(toProfileWhitelist: thread)
            }

            thread.updateGroupMembers()
        }

        if let unacceptedThread = self.unacceptedThread(at: indexPath) {

            if let topChatViewController = Navigator.topViewController as? ChatViewController {
                topChatViewController.updateThread(unacceptedThread)
            }

            unacceptedThread.updateGroupMembers()
        }
    }

    private func loadMessages() {
        viewModel.uiDatabaseConnection.asyncRead { [weak self] transaction in

            guard let strongSelf = self else { return }

            strongSelf.viewModel.acceptedThreadsMappings.update(with: transaction)
            strongSelf.viewModel.unacceptedThreadsMappings.update(with: transaction)

            var updatedSections: [ChatsMainPageSection] = []

            switch strongSelf.target {
            case .chatsMainPage:
                updatedSections.append(ChatsMainPageSection(type: .findPeople, items: [.findPeople]))

                if strongSelf.hasUnacceptedThreads {
                    updatedSections.append(ChatsMainPageSection(type: .messageRequests, items: [.messageRequests]))
                }

                var chatItems = [ChatsMainPageItem](repeating: .chat, count: strongSelf.acceptedThreadsCount)

                chatItems.append(.inviteFriend)
                updatedSections.append(ChatsMainPageSection(type: .chats, items: chatItems))

            case .messageRequestsPage:
                let chatItems = [ChatsMainPageItem](repeating: .chat, count: strongSelf.unacceptedThreadsCount)
                updatedSections.append(ChatsMainPageSection(type: .chats, items: chatItems))
            }

            strongSelf.sections = updatedSections

            DispatchQueue.main.async {
                strongSelf.output?.chatsDataSourceDidLoad()
            }
        }
    }

    private func messageRequestsCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let firstUnacceptedThread = unacceptedThread(at: IndexPath(row: 0, section: 0)) else {
            return UITableViewCell(frame: .zero)
        }

        let cellConfigurator = CellConfigurator()
        var cellData: TableCellData
        var accessoryType: UITableViewCellAccessoryType

        let requestsTitle = "\(Localized.messages_requests_title) (\(unacceptedThreadsCount))"
        let firstImage = firstUnacceptedThread.avatar()

        if let secondUnacceptedThread = unacceptedThread(at: IndexPath(row: 1, section: 0)) {
            let secondImage = secondUnacceptedThread.avatar()
            cellData = TableCellData(title: requestsTitle, doubleImage: (firstImage: firstImage, secondImage: secondImage))
            accessoryType = .disclosureIndicator
        } else {
            cellData = TableCellData(title: requestsTitle, leftImage: firstImage)
            accessoryType = .none
        }

        guard let cell = tableView?.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: cellData.components), for: indexPath) else { return UITableViewCell() }
        cellConfigurator.configureCell(cell, with: cellData)
        cell.accessoryType = accessoryType

        return cell
    }

    private func acceptableMessageRequestCell(for indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let thread = unacceptedThread(at: indexPath) else { return UITableViewCell(frame: .zero) }

        let avatar = thread.avatar()
        var subtitle = "..."
        var title = ""

        if thread.isGroupThread() {
            title = thread.name()
        } else if let recipient = thread.recipient() {
            title = recipient.nameOrDisplayName
        }

        if let message = thread.messages.last, let messageBody = message.body {
            switch SofaType(sofa: messageBody) {
            case .message:
                if message.hasAttachments() {
                    subtitle = Localized.attachment_message_preview_string
                } else {
                    subtitle = SofaMessage(content: messageBody).body
                }
            case .paymentRequest:
                subtitle = Localized.payment_request_message_preview_string
            case .payment:
                subtitle = Localized.payment_message_preview_string
            default:
                break
            }
        }

        let cellData = TableCellData(title: title, subtitle: subtitle, leftImage: avatar, doubleActionImages: (firstImage: ImageAsset.accept_thread_icon, secondImage: ImageAsset.decline_thread_icon))
        let cellConfigurator = CellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: cellData.components), for: indexPath) as? BasicTableViewCell else { return UITableViewCell(frame: .zero) }
        cellConfigurator.configureCell(cell, with: cellData)
        cell.actionDelegate = self

        return cell
    }

    private func chatMainPageCell(for indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell(frame: .zero)

        guard indexPath.section < numberOfSections else { return UITableViewCell() }
        let section = sections[indexPath.section]
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
            cell = messageRequestsCell(for: indexPath)
            cell.accessoryType = .disclosureIndicator
        case .chat:
            if let thread = acceptedThread(at: indexPath.row, in: 0) {
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

extension ChatsDataSource: BasicCellActionDelegate {

    func didTapFirstActionButton(_ cell: BasicTableViewCell) {
        guard let indexPath = tableView?.indexPath(for: cell) else { return }
        guard let thread = unacceptedThread(at: indexPath) else { return }

        ChatInteractor.acceptThread(thread)

        output?.didRequireOpenThread(thread)
    }

    func didTapSecondActionButton(_ cell: BasicTableViewCell) {
        guard let indexPath = tableView?.indexPath(for: cell) else { return }
        guard let thread = unacceptedThread(at: indexPath) else { return }

        ChatInteractor.declineThread(thread)
    }
}

extension ChatsDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If there is no user session, sections collection is empty
        // or if currently there are less sections and table view tried to reload after Yap insert notification,
        // but data source section are being updated
        guard section < sections.count else { return 0 }
        
        let chatsPageSection = sections[section]

        return chatsPageSection.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch target {
        case .chatsMainPage:
            return chatMainPageCell(for: indexPath, tableView: tableView)
        case .messageRequestsPage:
            return acceptableMessageRequestCell(for: indexPath, tableView: tableView)
        }
    }
}
