import UIKit
import SweetUIKit

open class ProfileController: UIViewController {

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = .white
        self.tabBarItem = UITabBarItem(title: "Profile", image: #imageLiteral(resourceName: "Profile"), tag: 2)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
    }
}
