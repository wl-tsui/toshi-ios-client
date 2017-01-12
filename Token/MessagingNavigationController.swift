import UIKit

public class MessagingNavigationController: UINavigationController {
    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.tabBarItem = UITabBarItem(title: "Messages", image: #imageLiteral(resourceName: "Activity"), tag: 0)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("")
    }
}
