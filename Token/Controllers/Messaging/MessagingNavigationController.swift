import UIKit

public class MessagingNavigationController: UINavigationController {

    let selectedThreadAddressKey = "SelectedThread"

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.tabBarItem = UITabBarItem(title: "Messages", image: #imageLiteral(resourceName: "messages"), tag: 0)
        self.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: move restoration to the tabbar controller, so we only restore the currently selected.
        if let address = UserDefaults.standard.string(forKey: self.selectedThreadAddressKey) {
            // we delay by one cycle and it's enough for UIKit to set the children viewcontrollers
            // for the navigation controller. Otherwise `viewcontrollers` will be nil and it wont restore.
            // Downside: it blinks the previous view for no.
            // TODO: move all of this the the navigator so we can restore the hiararchy straight from the app delegate.
            DispatchQueue.main.asyncAfter(seconds: 0.0) {
                self.openThread(withAddress: address)
            }
        }
    }

    public func openThread(withAddress address: String) {
        self.popToRootViewController(animated: false)
        guard let chatsController = self.viewControllers.first as? ChatsController else { fatalError() }

        let thread = chatsController.thread(withAddress: address)
        let messagesController = MessagesViewController(thread: thread, chatAPIClient: chatsController.chatAPIClient)

        self.pushViewController(messagesController, animated: false)
    }

    public func openThread(withThreadIdentifier identifier: String, animated: Bool) {
        self.popToRootViewController(animated: animated)
        guard let chatsController = self.topViewController as? ChatsController else { fatalError() }
        guard let thread = chatsController.thread(withIdentifier: identifier) else { return }

        let messagesController = MessagesViewController(thread: thread, chatAPIClient: chatsController.chatAPIClient)
        self.pushViewController(messagesController, animated: animated)
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? MessagesViewController {
            UserDefaults.standard.setValue(viewController.thread.contactIdentifier(), forKey: self.selectedThreadAddressKey)
        } else {
            UserDefaults.standard.removeObject(forKey: self.selectedThreadAddressKey)
        }
    }
}
