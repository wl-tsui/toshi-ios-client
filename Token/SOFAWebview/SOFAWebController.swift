import UIKit
import SweetUIKit
import WebKit

class SOFAWebController: UIViewController {

    enum Method: String {
        case getAccounts
        case signTransaction
        case approveTransaction
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
    private func jsCallback(callbackId: String, payload: String) {
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
            // alert noop
            break
        case .approveTransaction:
            // alert noop
            break
        }
    }
}
