import UIKit

open class TabBarController: UITabBarController {

    public var chatAPIClient: ChatAPIClient

    public init(chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient

        super.init(nibName: nil, bundle: nil)

        self.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        let messaging = MessagingNavigationController(rootViewController: ChatsTableController(chatAPIClient: chatAPIClient))

        self.title = messaging.title

        self.viewControllers = [messaging, ExtensionsController(), ContactsController(), ProfileController()]
        self.view.tintColor = Theme.tintColor
    }
}

extension TabBarController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print(viewController)
        self.title = viewController.title
    }
}
