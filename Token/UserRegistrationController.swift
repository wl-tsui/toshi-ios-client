import UIKit
import SweetFoundation
import SweetUIKit

open class UserRegistrationController: UIViewController {

    public var idAPIClient: IDAPIClient

    public init(idAPIClient: IDAPIClient) {
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)
    }

    private init() {
        fatalError()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
    }
}
