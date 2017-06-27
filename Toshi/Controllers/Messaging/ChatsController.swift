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
import SweetFoundation
import SweetUIKit

/// Displays current conversations.
open class ChatsController: SweetTableController {

    lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: TSThreadDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    public init() {
        super.init()

        self.title = "Recent"

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }

        self.registerNotifications()
        self.loadViewIfNeeded()

        self.showEmptyStateIfNeeded()
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.addSubviewsAndConstraints()

        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(ChatCell.self)
        self.tableView.showsVerticalScrollIndicator = true
        self.tableView.alwaysBounceVertical = true
        NotificationCenter.default.post(name: IDAPIClient.updateContactsNotification, object: nil, userInfo: nil)

        self.adjustEmptyView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate lazy var emptyStateContainerView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    fileprivate func addSubviewsAndConstraints() {
        self.view.addSubview(self.emptyStateContainerView)
        let topSpace: CGFloat = (self.navigationController?.navigationBar.frame.height ?? 0.0)
        self.emptyStateContainerView.set(height: self.view.frame.height - topSpace)
        self.emptyStateContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.emptyStateContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.emptyStateContainerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.view.layoutIfNeeded()
    }

    @discardableResult static func getOrCreateThread(for address: String) -> TSThread {
        var thread: TSThread?

        TSStorageManager.shared().dbConnection?.readWrite { transaction in
            var recipient = SignalRecipient(textSecureIdentifier: address, with: transaction)

            var shouldRequestContactsRefresh = false

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: address, relay: nil)
                shouldRequestContactsRefresh = true
            }

            recipient?.save(with: transaction)
            thread = TSContactThread.getOrCreateThread(withContactId: address, transaction: transaction)

            if shouldRequestContactsRefresh == true {
                self.requestContactsRefresh()
            }

            if thread?.archivalDate() != nil {
                thread?.unarchiveThread(with: transaction)
            }
        }

        return thread!
    }

    fileprivate static func requestContactsRefresh() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        appDelegate.contactsManager.refreshContacts()
    }

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = self.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        guard let viewConnection = self.uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewConnection else { return }

        let hasChangesForCurrentView = viewConnection.hasChanges(for: notifications)
        if !hasChangesForCurrentView {
            self.uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        viewConnection.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: self.mappings)

        if sectionChanges.count == 0 && messageRowChanges.count == 0 {
            return
        }

        // No need to animate the tableview if not being presented.
        // Avoids an issue where tableview will actually cause a crash on update
        // during a chat update.
        if self.navigationController?.topViewController == self && self.tabBarController?.selectedViewController == self.navigationController {
            self.tableView.beginUpdates()

            for rowChange in messageRowChanges as! [YapDatabaseViewRowChange] {
                switch rowChange.type {
                case .delete:
                    self.tableView.deleteRows(at: [rowChange.indexPath], with: .left)
                case .insert:
                    self.updateContactIfNeeded(at: rowChange.newIndexPath)
                    self.tableView.insertRows(at: [rowChange.newIndexPath], with: .right)
                case .move:
                    self.tableView.deleteRows(at: [rowChange.indexPath], with: .left)
                    self.tableView.insertRows(at: [rowChange.newIndexPath], with: .right)
                case .update:
                    self.tableView.reloadRows(at: [rowChange.indexPath], with: .automatic)
                }
            }

            self.tableView.endUpdates()
        } else {
            self.tableView.reloadData()
        }

        self.showEmptyStateIfNeeded()
    }

    private func showEmptyStateIfNeeded() {
        let shouldHideEmptyState = self.mappings.numberOfItems(inSection: 0) > 0

        self.makeEmptyView(hidden: shouldHideEmptyState)
    }

    func updateContactIfNeeded(at indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath), let address = thread.contactIdentifier() as String? {
            print("Updating contact infor for address: \(address).")

            self.idAPIClient.retrieveContact(username: address) { contact in
                if let contact = contact {
                    print("Updated contact info for \(contact.username)")
                }
            }
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func thread(withAddress address: String) -> TSThread? {
        var thread: TSThread?

        self.uiDatabaseConnection.read { transaction in
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

        self.uiDatabaseConnection.read { transaction in
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
}

extension ChatsController: Emptiable {

    var buttonPressed: Selector {
        return #selector(buttonPressed(sender:))
    }

    func emptyStateTitle() -> String {
        return "No chats yet"
    }

    func emptyStateDescription() -> String {
        return "Once you start a new conversation,\nyou'll see it here."
    }

    func emptyStateButtonTitle() -> String {
        return "Invite friends"
    }

    func sourceView() -> UIView {
        return self.emptyStateContainerView
    }

    func isScrollable() -> Bool {
        return true
    }

    func buttonPressed(sender _: AnyObject) {
        let shareController = UIActivityViewController(activityItems: ["Get Toshi, available for iOS and Android! (https://toshi.org)"], applicationActivities: [])

        Navigator.presentModally(shareController)
    }
}

extension ChatsController: UITableViewDelegate {

    open func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 82
    }

    open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath) as TSThread? {
            let chatController = ChatController(thread: thread)
            self.navigationController?.pushViewController(chatController, animated: true)
        }
    }

    public func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Delete") { _, indexPath in
            if let thread = self.thread(at: indexPath) as TSThread? {

                TSStorageManager.shared().dbConnection?.asyncReadWrite { transaction in
                    thread.archiveThread(with: transaction)
                }
            }
        }

        return [action]
    }
}

extension ChatsController: UITableViewDataSource {

    open func numberOfSections(in _: UITableView) -> Int {
        return Int(self.mappings.numberOfSections())
    }

    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ChatCell.self, for: indexPath)
        let thread = self.thread(at: indexPath)

        // TODO: deal with last message from thread. It should be last visible message.
        cell.thread = thread

        return cell
    }
}
