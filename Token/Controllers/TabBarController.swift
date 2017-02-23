import UIKit
import UserNotifications

let TabBarItemTitleOffset: CGFloat = -3.0

open class TabBarController: UITabBarController {

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: TSThreadDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    let yap = Yap.sharedInstance

    public var chatAPIClient: ChatAPIClient

    public var idAPIClient: IDAPIClient

    private var homeController: HomeNavigationController!
    private var messagingController: MessagingNavigationController!
    private var appsController: AppsNavigationController!
    private var contactsController: ContactsNavigationController!
    private var settingsController: SettingsNavigationController!

    public init(chatAPIClient: ChatAPIClient, idAPIClient: IDAPIClient) {
        self.chatAPIClient = chatAPIClient
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)

        self.delegate = self

        let notificationController = NotificationCenter.default
        notificationController.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func yapDatabaseDidChange(notification: NSNotification) {
        defer { self.updateBadge() }
        
        let notifications = self.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // TODO: Since this is used in more than one place, we should look into abstracting this away, into our own
        // table/collection view backing model.
        let viewConnection = self.uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection
        let hasChangesForCurrentView = viewConnection.hasChanges(for: notifications)

        guard hasChangesForCurrentView else {
            self.uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        if self.selectedViewController == self.messagingController {
            return
        }

        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        viewConnection.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: self.mappings)

        if messageRowChanges.count == 0 {
            return
        }

        self.uiDatabaseConnection.asyncRead { transaction in
            for change in messageRowChanges as! [YapDatabaseViewRowChange] {
                guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError("!!!!") }

                switch change.type {
                case .update:
                    guard let thread = dbExtension.object(at: change.indexPath, with: self.mappings) as? TSThread else { continue }
                    guard let last = thread.visibleIncomingInteractions.last, !last.wasRead else { continue }

                    if let date = self.yap.retrieveObject(for: thread.name(), in: "UnreadMessageLocalNotifications") as? Date, date == last.date() {
                        continue
                    } else {
                        self.yap.insert(object: last.date(), for: thread.name(), in: "UnreadMessageLocalNotifications")
                    }

                    let content = UNMutableNotificationContent()
                    content.title = thread.name()

                    if let body = last.body, let sofa = SofaWrapper.wrapper(content: body) as? SofaMessage {
                        content.body = sofa.body
                    } else {
                        content.body = "New message."
                    }

                    content.sound = UNNotificationSound.default()

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: thread.name(), content: content, trigger: trigger)

                    let center = UNUserNotificationCenter.current()
                    center.add(request, withCompletionHandler: nil)
                default:
                    break
                }
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Refactor all this navigation controllers subclasses into one, they have similar code
        self.homeController = HomeNavigationController(rootViewController: HomeController())
        self.messagingController = MessagingNavigationController(rootViewController: ChatsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.appsController = AppsNavigationController(rootViewController: AppsController())
        self.contactsController = ContactsNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.settingsController = SettingsNavigationController(rootViewController: ProfileController(idAPIClient: self.idAPIClient))

        self.viewControllers = [
            self.homeController,
            self.messagingController,
            self.appsController,
            self.contactsController,
            self.settingsController,
        ]

        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor

        let index = UserDefaults.standard.integer(forKey: self.tabBarSelectedIndexKey)
        self.selectedIndex = index

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
        }

        self.updateBadge()
    }

    public func updateBadge() {
        var count: UInt = 0
        self.uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection(), using: { (_, object, _, stop) in
                if let thread = object as? TSThread {
                    count += TSMessagesManager.shared().unreadMessages(in: thread)
                }
            })
        }

        if count > 0 {
            self.messagingController.tabBarItem.badgeValue = "\(count)"
            self.messagingController.tabBarItem.badgeColor = .red
        } else {
            self.messagingController.tabBarItem.badgeValue = nil
        }
    }

    public func displayMessage(forAddress address: String) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address)
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        if let index = self.viewControllers?.index(of: viewController) {
            UserDefaults.standard.set(index, forKey: self.tabBarSelectedIndexKey)
        }
    }
}
