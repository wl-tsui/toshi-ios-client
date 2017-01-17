import UIKit
import SweetUIKit
import SweetSwift

public extension Array {
    public var any: Element? {
        return self[Int(arc4random_uniform(UInt32(self.count)))] as Element
    }
}

open class ContactsController: SweetTableController {

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

    public init(idAPIClient: IDAPIClient) {
        self.idAPIClient = idAPIClient

        super.init(style: .plain)

        self.tabBarItem = UITabBarItem(title: "Contacts", image: #imageLiteral(resourceName: "Contacts"), tag: 1)
        self.title = "Contacts"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(ContactCell.self)

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
}

extension ContactsController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ContactCell.self, for: indexPath)
        let contact = self.contacts[indexPath.row]

        cell.contact = contact

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
        guard self.searchController.isActive else { return }

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
