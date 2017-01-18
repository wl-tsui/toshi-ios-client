import UIKit

public class MessagingNavigationController: UINavigationController {

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.title = "Messages"
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

//        self.title = "Messages"
//        self.tabBarItem = UITabBarItem(title: "Messages", image: #imageLiteral(resourceName: "Activity"), tag: 0)
        self.tabBarItem = UITabBarItem(title: "Contacts", image: #imageLiteral(resourceName: "Contacts"), tag: 0)
        self.title = "Contacts"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.barTintColor = Theme.tintColor
    }
}
