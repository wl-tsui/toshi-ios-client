import UIKit

open class TabBarController: UITabBarController {

    public var chatAPIClient: ChatAPIClient

    public init(chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        let messaging = MessagingNavigationController(rootViewController: ChatsTableController(chatAPIClient: chatAPIClient))
        self.viewControllers = [messaging, ExtensionsController(), ContactsController(), ProfileController()]
    }
}
