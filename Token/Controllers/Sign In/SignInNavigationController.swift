import UIKit

public class SignInNavigationController: UINavigationController {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    convenience init() {
        self.init(rootViewController: SignInController(idAPIClient: IDAPIClient.shared))
        self.title = "Sign in"
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
}
