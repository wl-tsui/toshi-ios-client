import UIKit

protocol PaymentRequestControllerDelegate: class {
    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?)
}

class PaymentRequestController: PaymentController {
    weak var delegate: PaymentRequestControllerDelegate?

    lazy var continueBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(sendRequest))

        return item
    }()

    lazy var cancelBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelRequest))

        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let title = UIBarButtonItem(title: "Request Payment", style: .plain, target: nil, action: nil)
        title.setTitleTextAttributes([NSFontAttributeName: Theme.semibold(size: 17)], for: .normal)

        self.toolbar.items = [self.cancelBarButton, spacing, title, spacing, self.continueBarButton]
    }

    func cancelRequest() {
        self.delegate?.paymentRequestControllerDidFinish(valueInWei: nil)
    }

    func sendRequest() {
        self.delegate?.paymentRequestControllerDidFinish(valueInWei: self.valueInWei)
    }
}
