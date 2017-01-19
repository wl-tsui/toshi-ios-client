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

        let messaging = MessagingNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.title = messaging.title

        self.viewControllers = [messaging, ProfileController(idAPIClient: self.idAPIClient)]
        self.view.tintColor = Theme.tintColor
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.title = viewController.title

        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        self.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem
        self.navigationItem.leftBarButtonItem = viewController.navigationItem.leftBarButtonItem
    }
}
