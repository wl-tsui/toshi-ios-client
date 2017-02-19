import UIKit

open class TabBarController: UITabBarController {

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    public var chatAPIClient: ChatAPIClient

    open override var selectedIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedIndex, forKey: self.tabBarSelectedIndexKey)
        }
    }

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
            self.settingsController
        ]

        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor

        let index = UserDefaults.standard.integer(forKey: self.tabBarSelectedIndexKey)
        self.selectedIndex = index
    }

    public func displayMessage(forAddress address: String) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address)
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets
    }
}
