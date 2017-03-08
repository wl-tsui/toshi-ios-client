import UIKit

protocol PaymentSendControllerDelegate: class {
    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?)
}

class PaymentSendController: PaymentController {
    weak var delegate: PaymentSendControllerDelegate?

    lazy var continueBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(send))

        return item
    }()

    lazy var cancelBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let title = UIBarButtonItem(title: "Send Payment", style: .plain, target: nil, action: nil)
        title.setTitleTextAttributes([NSFontAttributeName: Theme.semibold(size: 17)], for: .normal)

        self.toolbar.items = [self.cancelBarButton, spacing, title, spacing, self.continueBarButton]
    }

    func cancel() {
        self.delegate?.paymentSendControllerDidFinish(valueInWei: nil)
    }

    func send() {
        self.delegate?.paymentSendControllerDidFinish(valueInWei: self.valueInWei)
    }
}
