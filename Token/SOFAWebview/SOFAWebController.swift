// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import SweetUIKit
import WebKit

class SOFAWebController: UIViewController {

    enum Method: String {
        case getAccounts
        case signTransaction
        case approveTransaction
    }

    fileprivate var etherAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    fileprivate let rcpUrl = "https://propsten.infura.io/"

    fileprivate lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()

        var js = "window.SOFA = {config: {rcpUrl: '" + self.rcpUrl + "'}}; "

        if let filepath = Bundle.main.path(forResource: "sofa-web3", ofType: "js") {
            do {
                js += try String(contentsOfFile: filepath)
                print("Loaded sofa.js")
            } catch {
                print("Failed to load sofa.js")
            }
        } else {
            print("Sofa.js not found in bundle")
        }

        var userScript: WKUserScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)

        configuration.userContentController.add(self, name: Method.getAccounts.rawValue)
        configuration.userContentController.add(self, name: Method.signTransaction.rawValue)
        configuration.userContentController.add(self, name: Method.approveTransaction.rawValue)

        configuration.userContentController.addUserScript(userScript)

        let view = WKWebView(frame: self.view.frame, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.isScrollEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.navigationDelegate = self

        return view
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate lazy var backButton: UIButton = {
        let view = UIButton(type: .custom)
        view.bounds.size = CGSize(width: 44, height: 44)
        view.setImage(#imageLiteral(resourceName: "web_back").withRenderingMode(.alwaysTemplate), for: .normal)
        view.addTarget(self, action: #selector(self.didTapBackButton), for: .touchUpInside)

        return view
    }()

    fileprivate lazy var forwardButton: UIButton = {
        let view = UIButton(type: .custom)
        view.bounds.size = CGSize(width: 44, height: 44)
        view.setImage(#imageLiteral(resourceName: "web_forward").withRenderingMode(.alwaysTemplate), for: .normal)
        view.addTarget(self, action: #selector(self.didTapForwardButton), for: .touchUpInside)

        return view
    }()

    fileprivate lazy var backBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: self.backButton)
    }()

    fileprivate lazy var forwardBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: self.forwardButton)
    }()

    fileprivate lazy var toolbar: UIToolbar = {
        let view = UIToolbar(withAutoLayout: true)

        let share = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let placeholder = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        placeholder.width = 44

        view.items = [self.backBarButtonItem, spacing, self.forwardBarButtonItem, spacing, share, spacing, placeholder]

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.webView)
        self.view.addSubview(self.toolbar)

        NSLayoutConstraint.activate([
            self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.toolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        self.toolbar.set(height: 44)
        self.hidesBottomBarWhenPushed = true
        self.webView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.webView.fillSuperview()
        self.webView.bottomAnchor.constraint(equalTo: self.toolbar.topAnchor).isActive = true
    }

    fileprivate func displayPaymentConfirmation(userInfo: UserInfo, parameters: [String: Any], callbackId: String) {

        guard let valueString = parameters["value"] as? String else { return }

        let paymentConfirmationController = PaymentConfirmationController(userInfo: userInfo, value: NSDecimalNumber(hexadecimalString: valueString))

        let declineIcon = UIImage(named: "cross")
        let declineAction = Action(title: "Decline", titleColor: UIColor(white: 0.5, alpha: 1.0), icon: declineIcon) { _ in
            paymentConfirmationController.dismiss(animated: true, completion: nil)
        }

        let approveIcon = UIImage(named: "check")
        let approveAction = Action(title: "Approve", titleColor: Theme.tintColor, icon: approveIcon) { _ in
            self.etherAPIClient.createUnsignedTransaction(parameters: parameters) { transaction, _ in
                let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction!))"

                let payload = "{\\\"error\\\": null, \\\"result\\\": [\\\"" + signedTransaction + "\\\"]}"
                self.jsCallback(callbackId: callbackId, payload: payload)

                paymentConfirmationController.dismiss(animated: true, completion: nil)
            }
        }

        paymentConfirmationController.actions = [declineAction, approveAction]

        self.present(paymentConfirmationController, animated: true)
    }

    public func load(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        self.loadViewIfNeeded()
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    @objc
    fileprivate func didTapBackButton() {
        self.webView.goBack()
    }

    @objc
    fileprivate func didTapForwardButton() {
        self.webView.goForward()
    }
}

extension SOFAWebController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        self.backBarButtonItem.isEnabled = webView.canGoBack
        self.forwardBarButtonItem.isEnabled = webView.canGoForward
    }
}

extension SOFAWebController: WKScriptMessageHandler {
    fileprivate func jsCallback(callbackId: String, payload: String) {
        let js = "SOFA.callback(\"" + callbackId + "\",\"" + payload + "\")"

        self.webView.evaluateJavaScript("javascript:" + js) { jsReturnValue, error in
            if let error = error {
                print("Error: \(error)")
            } else if let newCount = jsReturnValue as? Int {
                print("Returned value: \(newCount)")
            } else {
                print("No return from JS")
            }
        }
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let method = Method(rawValue: message.name) else { return print("failed \(message.name)") }
        guard let callbackId = (message.body as! NSDictionary).value(forKey: "callback") as? String else { return print("missing callback id") }

        switch method {
        case .getAccounts:
            let payload = "{\\\"error\\\": null, \\\"result\\\": [\\\"" + Cereal.shared.address + "\\\"]}"
            self.jsCallback(callbackId: callbackId, payload: payload)

            break
        case .signTransaction:
            guard let messageBody = message.body as? [String: Any], let tx = messageBody["tx"] as? [String: Any] else {
                return
            }

            guard let from = tx["from"] as? String else {
                let payload = "{\\\"error\\\": \\\"Property From couldn't be read\\\"}"
                self.jsCallback(callbackId: callbackId, payload: payload)

                return
            }
            guard let to = tx["to"] as? String else {
                let payload = "{\\\"error\\\": \\\"Property To couldn't be read\\\"}"
                self.jsCallback(callbackId: callbackId, payload: payload)

                return
            }

            guard let data = tx["data"] as? String,
                let gas = tx["gas"] as? String,
                let gasPrice = tx["gasPrice"] as? String else { return }

            IDAPIClient.shared.retrieveUser(username: to) { user in
                let value = tx["value"] as? String ?? "0.0"

                let parameters: [String: Any] = [
                    "from": from,
                    "to": to,
                    "value": value,
                    "gas": gas,
                    "gasPrice": gasPrice,
                    "data": data,
                ]

                var userInfo = UserInfo(address: to, avatar: nil, name: nil, username: to, isLocal: false)

                if let user = user as TokenUser? {
                    let avatar = user.avatar != nil ? user.avatar : UIImage(color: UIColor.lightGray)
                    userInfo.avatar = avatar
                    userInfo.username = user.username
                    userInfo.name = user.name
                    userInfo.isLocal = true
                }

                self.displayPaymentConfirmation(userInfo: userInfo, parameters: parameters, callbackId: callbackId)
            }

            break
        case .approveTransaction:
            let payload = "{\\\"error\\\": null, \\\"result\\\": true}"
            self.jsCallback(callbackId: callbackId, payload: payload)

            break
        }
    }
}
