import UIKit
import UserNotifications

let TabBarItemTitleOffset: CGFloat = -3.0

open class TabBarController: UITabBarController {

    public enum Tab {
        case home
        case messaging
        case apps
        case contacts
        case settings
    }

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    public var chatAPIClient: ChatAPIClient

    public var idAPIClient: IDAPIClient

    internal var homeController: HomeNavigationController!
    internal var messagingController: MessagingNavigationController!
    internal var appsController: AppsNavigationController!
    internal var contactsController: ContactsNavigationController!
    internal var settingsController: SettingsNavigationController!

    public init(chatAPIClient: ChatAPIClient, idAPIClient: IDAPIClient) {
        self.chatAPIClient = chatAPIClient
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)

        self.delegate = self
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Refactor all this navigation controllers subclasses into one, they have similar code
        self.homeController = HomeNavigationController(rootViewController: HomeController())
        self.messagingController = MessagingNavigationController(rootViewController: ChatsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.appsController = AppsNavigationController(rootViewController: AppsController())
        self.contactsController = ContactsNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.settingsController = SettingsNavigationController(rootViewController: SettingsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))

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
    }

    public func displayMessage(forAddress address: String) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address)
    }

    public func `switch`(to tab: Tab) {
        switch tab {
        case .home:
            self.selectedIndex = 0
        case .messaging:
            self.selectedIndex = 1
        case .apps:
            self.selectedIndex = 2
        case .contacts:
            self.selectedIndex = 3
        case .settings:
            self.selectedIndex = 4
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        SoundPlayer.playSound(type: .menuButton)

        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        if let index = self.viewControllers?.index(of: viewController) {
            UserDefaults.standard.set(index, forKey: self.tabBarSelectedIndexKey)
        }
    }
}
