import UIKit
import SweetUIKit
import SweetSwift
import YapDatabase

public extension Array {
    public var any: Element? {
        return self[Int(arc4random_uniform(UInt32(self.count)))] as Element
    }
}

open class ContactsController: SweetTableController {

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

    let yap: Yap = Yap.sharedInstance

    var contacts = [TokenContact]()

    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.barTintColor = Theme.tintColor
        controller.searchBar.tintColor = Theme.lightTextColor
        controller.searchBar.delegate = self

        return controller
    }()

    public init(idAPIClient: IDAPIClient, chatAPIClient: ChatAPIClient) {
        self.idAPIClient = idAPIClient
        self.chatAPIClient = chatAPIClient

        super.init(style: .plain)

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }

        self.registerNotifications()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(ContactCell.self)
        self.tableView.register(ChatCell.self)

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.tableView.separatorStyle = .none
        self.tableView.tableHeaderView = self.searchController.searchBar

        self.displayContacts()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.definesPresentationContext = true
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.navigationItem.rightBarButtonItem = nil
        self.definesPresentationContext = false
    }

    open func displayContacts() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let contactsManager = delegate.contactsManager
            self.contacts = contactsManager.tokenContacts()
            self.tableView.reloadData()
        }
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

        guard !self.searchController.isActive else { return }

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

extension ContactsController: UITableViewDataSource {

    open func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchController.isActive {
            return 1
        }
        
        return Int(self.mappings.numberOfSections())
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive {
            return self.contacts.count
        }

        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.searchController.isActive {
            let cell = tableView.dequeue(ContactCell.self, for: indexPath)
            cell.contact = self.contacts[indexPath.row]

            return cell
        } else {
            let cell = tableView.dequeue(ChatCell.self, for: indexPath)
            cell.thread = self.thread(at: indexPath)

            return cell
        }
    }
}

extension ContactsController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.searchController.isActive  {
            // show add contact page
            let contact = self.contacts[indexPath.row]

            let alert = UIAlertController.dismissableAlert(title: "Add Contact?", message: "Would you like to add \(contact.username) to your contacts?")

            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
                if !self.yap.containsObject(for: contact.address, in: TokenContact.collectionKey) {
                    self.yap.insert(object: contact.JSONData, for: contact.address, in: TokenContact.collectionKey)
                }

                TSStorageManager.shared().dbConnection.readWrite { transaction in
                    var recipient = SignalRecipient(textSecureIdentifier: contact.address, with: transaction)

                    if recipient == nil {
                        recipient = SignalRecipient(textSecureIdentifier: contact.address, relay: nil, supportsVoice: false)
                    }

                    recipient?.save(with: transaction)

                    TSContactThread.getOrCreateThread(withContactId: contact.address, transaction: transaction)
                }
            }))
            
            self.present(alert, animated: true)
        } else {
            // message contact
            let thread = self.thread(at: indexPath)
            let messagesController = MessagesViewController(thread: thread, chatAPIClient: chatAPIClient)

            if let nav = self.view.window?.rootViewController as? UINavigationController {
                nav.pushViewController(messagesController, animated: true)
            } else {
                print("Where is navigation?")
            }
        }
    }
}

extension ContactsController: UISearchBarDelegate {

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        self.displayContacts()
    }
}

extension ContactsController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, text.length > 0 {
            self.idAPIClient.searchContacts(name: text) { contacts in
                self.contacts = contacts
                print(self.contacts)
                self.tableView.reloadData()
            }
        }
    }
}
