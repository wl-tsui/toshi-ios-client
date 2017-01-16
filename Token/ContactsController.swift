import UIKit
import SweetUIKit

public extension Array {
    public var any: Element? {
        return self[Int(arc4random_uniform(UInt32(self.count)))] as Element
    }
}

class ContactCell: UITableViewCell {
    var contact: TokenContact? {
        didSet {
            // self.avatarImageView.image = self.contact?.avatar
            self.usernameLabel.text = self.contact?.username
            self.nameLabel.text = self.contact?.name
        }
    }

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = [#imageLiteral(resourceName: "daniel"), #imageLiteral(resourceName: "igor"), #imageLiteral(resourceName: "colin")].any

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.nameLabel)

        let margin: CGFloat = 12.0
        let size: CGFloat = 44.0

        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.layer.cornerRadius = size/2

        self.avatarImageView.set(height: size)
        self.avatarImageView.set(width: size)
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true
        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true

        self.nameLabel.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true

        self.usernameLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: size).isActive = true
        self.usernameLabel.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.nameLabel.rightAnchor, constant: margin).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
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
        controller.searchBar.barTintColor = Theme.tintColor
        controller.searchBar.tintColor = Theme.lightTextColor

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

                let thread = TSContactThread.getOrCreateThread(withContactId: contact.address, transaction: transaction)
            }
        }))

        self.present(alert, animated: true)
    }
}

extension ContactsController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        self.idAPIClient.searchContacts(name: searchController.searchBar.text ?? "") { contacts in
            self.contacts = contacts
            self.tableView.reloadData()
        }
    }
}
