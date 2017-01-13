import UIKit

public class RootNavigationController: UINavigationController {
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.barTintColor = Theme.tintColor
    }
}
