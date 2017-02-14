import UIKit
import SweetUIKit
import CoreImage

class QRCodeController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    lazy var qrCodeImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.set(height: 300)
        view.set(width: 300)

        return view
    }()

    lazy var toolbar: UIToolbar = {
        let view = UIToolbar(withAutoLayout: true)
        view.delegate = self

        view.barStyle = .black
        view.barTintColor = .black
        view.tintColor = .white

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(QRCodeController.didCancel))
        view.items = [space, cancel]

        return view
    }()

    convenience init(string: String) {
        self.init(nibName: nil, bundle: nil)

        self.qrCodeImageView.image = UIImage.imageQRCode(for: User.current!.address, resizeRate: 20.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .black
        self.view.addSubview(self.qrCodeImageView)
        self.view.addSubview(self.toolbar)

        self.toolbar.attachToTop(viewController: self)

        self.qrCodeImageView.set(height: 300)
        self.qrCodeImageView.set(width: 300)
        self.qrCodeImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.qrCodeImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }

    func didCancel() {
        self.dismiss(animated: true)
    }
}

extension QRCodeController: UIToolbarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
