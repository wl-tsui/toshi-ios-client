import UIKit
import SweetFoundation
import SweetUIKit

public class ChatsTableController: SweetTableController {

    // TODO: remove default value
    // 0xdfd98974dd99ea01b73b9992ef106d50c4a38bde == igor android
    // 0xe78f05d661549c747717989fc964f1ce08a6f477 == colin
    // 0x8d4b8054cc6a7e5321d99f8aa494e1e6b7fca0c8 == iphone elland
    // 0x84c3e9ee79279ee27fcb16bdbc2d2bbe0080b114 == SE simulator

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

    var chatAPIClient: ChatAPIClient

    init(chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient

        super.init()

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Messages"

        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(ChatCell.self)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.reloadData()
    }

    func thread(at indexPath: IndexPath) -> TSThread {
        var thread: TSThread? = nil
        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSThread else { fatalError() }

            thread = object
        }

        return thread!
    }
}

extension ChatsTableController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

    public func numberOfSections(in tableView: UITableView) -> Int {
        return Int(self.mappings.numberOfSections())
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ChatCell.self, for: indexPath)
        let thread = self.thread(at:indexPath)

        cell.thread = thread
        
        return cell
    }
}
