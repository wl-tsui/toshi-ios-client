import UIKit
import SweetUIKit
import SweetSwift
import CameraScanner

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

    var contacts = [TokenContact]()

    lazy var scannerController: ScannerViewController = {
        let controller = ScannerViewController(instructions: "Scan a profile code or QR code", types: [.qrCode])

        controller.delegate = self

        return controller
    }()

    lazy var scanContactButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(didTapScanContactButton))

        return item
    }()

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

        self.title = "Contacts"

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

        self.navigationItem.rightBarButtonItem = self.scanContactButton
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.navigationItem.rightBarButtonItem = nil
        self.definesPresentationContext = false
    }

    func displayContacts() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let contactsManager = delegate.contactsManager
            self.contacts = contactsManager.tokenContacts()
            self.tableView.reloadData()
        }
    }

    func didTapScanContactButton() {
        _ = self.scannerController.view
        self.scannerController.toolbar.setItems([self.scannerController.cancelItem], animated: true)
        self.present(self.scannerController, animated: true)
    }

    func registerNotifications() {
        let notificationController = NotificationCenter.default
        notificationController.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
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
        let cell = tableView.dequeue(ContactCell.self, for: indexPath)

        if self.searchController.isActive {
            cell.contact = self.contacts[indexPath.row]
        } else {
            let thread = self.thread(at: indexPath)
            let delegate = UIApplication.shared.delegate as! AppDelegate

            let contact = delegate.contactsManager.tokenContact(forAddress: thread.contactIdentifier())

            cell.contact = contact
        }

        return cell
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
        self.searchController.isActive = false
        self.tableView.reloadData()

        // show add contact page
        let contact = self.contacts[indexPath.row]
        let contactController = ContactController(contact: contact, idAPIClient: self.idAPIClient)

        self.navigationController?.pushViewController(contactController, animated: true)
    }
}

extension ContactsController: ScannerViewControllerDelegate {

    public func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        self.dismiss(animated: true)
    }

    public func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        self.idAPIClient.findContact(name: result) { contact in
            guard let contact = contact else { return }

            TSStorageManager.shared().dbConnection.readWrite { transaction in
                var recipient = SignalRecipient(textSecureIdentifier: contact.address, with: transaction)

                if recipient == nil {
                    recipient = SignalRecipient(textSecureIdentifier: contact.address, relay: nil, supportsVoice: false)
                }

                recipient?.save(with: transaction)

                TSContactThread.getOrCreateThread(withContactId: contact.address, transaction: transaction)
            }

            print("Added contact info for \(contact.username)")

            self.tableView.reloadData()
            self.dismiss(animated: true)
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
                self.tableView.reloadData()
            }
        }
    }
}
