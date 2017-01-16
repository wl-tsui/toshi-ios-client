import UIKit
import SweetFoundation
import SweetUIKit
import YapDatabase

/// Displays current conversations. Should be merged with ContactsController in the near future.
open class ChatsTableController: SweetTableController {

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

    public init(chatAPIClient: ChatAPIClient, idAPIClient: IDAPIClient) {
        self.chatAPIClient = chatAPIClient
        self.idAPIClient = idAPIClient

        super.init()

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }

        self.registerNotifications()
    }

    public required init?(coder aDecoder: NSCoder) {
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
    }

    func registerNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func yapDatabaseDidChange(notification: NSNotification) {
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

        for rowChange in (messageRowChanges as! [YapDatabaseViewRowChange]) {

            switch (rowChange.type) {
            case .delete:
                self.tableView.deleteRows(at: [rowChange.indexPath], with: .left)
            case .insert:
                self.updateContactIfNeeded(at: rowChange.newIndexPath)
                self.tableView.insertRows(at: [rowChange.newIndexPath], with: .right)
            case .move:
                self.tableView.deleteRows(at: [rowChange.indexPath], with: .left)
                self.tableView.insertRows(at: [rowChange.newIndexPath], with: .right)
            case .update:
                self.tableView.reloadRows(at: [rowChange.indexPath], with: .middle)
            }
        }

        self.tableView.endUpdates()
    }

    func updateContactIfNeeded(at indexPath: IndexPath) {
        let thread = self.thread(at: indexPath)
        let address = thread.contactIdentifier()!
        print("Updating contact infor for address: \(address).")

        self.idAPIClient.findContact(name: address) { (contact) in
            if let contact = contact {
                print("Added contact info for \(contact.username)")

                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.tableView.endUpdates()
            }
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread {
        var thread: TSThread? = nil
        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension: YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSThread else { fatalError() }

            thread = object
        }

        return thread!
    }
}

extension ChatsTableController: UITableViewDelegate {

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let thread = self.thread(at: indexPath)
        let messagesController = MessagesViewController(thread: thread, chatAPIClient: chatAPIClient)
        if let nav = self.view.window?.rootViewController as? UINavigationController {
            nav.pushViewController(messagesController, animated: true)
        } else {
            print("Where is navigation?")
        }
    }
}

extension ChatsTableController: UITableViewDataSource {

    open func numberOfSections(in tableView: UITableView) -> Int {
        return Int(self.mappings.numberOfSections())
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ChatCell.self, for: indexPath)
        let thread = self.thread(at: indexPath)

        cell.thread = thread

        return cell
    }
}
