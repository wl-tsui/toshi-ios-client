import UIKit
import SweetUIKit

open class ExtensionsController: SweetCollectionController {

    public init() {
        super.init()

        self.collectionView.backgroundColor = .white
        self.tabBarItem = UITabBarItem(title: "Extensions", image: #imageLiteral(resourceName: "Extensions"), tag: 3)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
