import UIKit

open class TabBarController: UITabBarController {

    public var chatAPIClient: ChatAPIClient

    public var idAPIClient: IDAPIClient

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
        let home = HomeNavigationController(rootViewController: HomeController())
        let messaging = MessagingNavigationController(rootViewController: ChatsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        let apps = AppsNavigationController(rootViewController: AppsController())
        let contacts = ContactsNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        let settings = SettingsNavigationController(rootViewController: ProfileController(idAPIClient: self.idAPIClient))

        self.viewControllers = [home, messaging, apps, contacts, settings]
        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets
    }
}
