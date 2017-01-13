import UIKit
import SweetFoundation
import SweetUIKit
import YapDatabase

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

    public init(chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient

        super.init()

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(ChatCell.self)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.reloadData()
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
        let thread = self.thread(at:indexPath)
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
        let thread = self.thread(at:indexPath)

        cell.thread = thread
        
        return cell
    }
}
