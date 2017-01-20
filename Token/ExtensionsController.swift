import UIKit
import SweetUIKit

open class ExtensionsController: SweetCollectionController {

    public init() {
        super.init()

        self.collectionView.backgroundColor = Theme.viewBackgroundColor
        self.tabBarItem = UITabBarItem(title: "Apps", image: #imageLiteral(resourceName: "apps"), tag: 3)
        self.title = "Apps"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }
}
