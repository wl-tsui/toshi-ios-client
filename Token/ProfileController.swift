import UIKit
import SweetUIKit

open class ProfileController: UIViewController {

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = .white
        self.tabBarItem = UITabBarItem(title: "Profile", image: #imageLiteral(resourceName: "Profile"), tag: 2)
        self.title = "Profile"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }
}
