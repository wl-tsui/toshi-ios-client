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

    public var chatAPIClient: ChatAPIClient

    public var idAPIClient: IDAPIClient

    public init(idAPIClient: IDAPIClient, chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient
        self.idAPIClient = idAPIClient

        super.init()

        self.title = "Messages"

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }

        self.registerNotifications()

        let _ = self.view // force load view to preload images
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(ChatCell.self)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.post(name: IDAPIClient.updateContactsNotification, object: nil, userInfo: nil)
    }

    func contactsDidUpdate() {
        self.tableView.reloadData()
    }

    func registerNotifications() {
        let notificationController = NotificationCenter.default
        notificationController.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
        notificationController.addObserver(self, selector: #selector(ChatsController.contactsDidUpdate), name: TokenContact.didUpdateContactInfoNotification, object: nil)
    }

    func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = self.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        let viewConnection = self.uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection
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
    }

    func updateContactIfNeeded(at indexPath: IndexPath) {
        let thread = self.thread(at: indexPath)
        let address = thread.contactIdentifier()!
        print("Updating contact infor for address: \(address).")

        self.idAPIClient.findContact(name: address) { contact in
            if let contact = contact {
                print("Updated contact info for \(contact.username)")
            }
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread {
        var thread: TSThread?
        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSThread else { fatalError() }

            thread = object
        }

        return thread!
    }

    func thread(withAddress address: String) -> TSThread {
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

        return thread!
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

extension ChatsController: UITableViewDelegate {

    open func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let thread = self.thread(at: indexPath)
        let messagesController = MessagesViewController(thread: thread, chatAPIClient: self.chatAPIClient)
        self.navigationController?.pushViewController(messagesController, animated: true)
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
