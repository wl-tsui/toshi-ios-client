import UIKit
import SweetUIKit

open class ContactsController: SweetTableController {

    public init() {
        super.init()

        self.tabBarItem = UITabBarItem(title: "Contacts", image: #imageLiteral(resourceName: "Contacts"), tag: 1)
        self.title = "Contacts"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }
}
