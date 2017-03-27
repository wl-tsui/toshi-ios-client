import UIKit
import SweetUIKit

open class SignInController: UIViewController {

    let idAPIClient: IDAPIClient

    private init() {
        fatalError()
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public init(idAPIClient: IDAPIClient) {
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)
        self.title = "Sign in"
    }

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(withAutoLayout: true)
        view.alwaysBounceVertical = true
        view.delaysContentTouches = false

        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    private lazy var usernameField: InputField = {
        InputField(type: .username)
    }()

    private lazy var passwordField: InputField = {
        InputField(type: .password)
    }()

    private lazy var footnote: Footnote = {
        Footnote(text: "This is your 12 word phrase, separated by spaces")
    }()

    private lazy var signInButton: ActionButton = {
        let view = ActionButton(withAutoLayout: true)
        view.title = "Sign in"

        return view
    }()

    private lazy var scanQRButton: ActionButton = {
        let view = ActionButton(withAutoLayout: true)
        view.title = "Scan QR to sign in"
        view.style = .secondary

        return view
    }()

    private lazy var createAccountButton: ActionButton = {
        let view = ActionButton(withAutoLayout: true)
        view.title = "Create a new account"
        view.style = .plain

        return view
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Theme.settingsBackgroundColor

        self.addSubviewsAndConstraints()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    func tap(_: UITapGestureRecognizer) {
        self.usernameField.textField.resignFirstResponder()
        self.passwordField.textField.resignFirstResponder()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // this close button is temporary
        let closeItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close(_:)))
        closeItem.title = "Close"
        self.navigationItem.leftBarButtonItem = closeItem

        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        self.navigationItem.backBarButtonItem = backItem
    }

    func close(_: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    private func addSubviewsAndConstraints() {

        let margin: CGFloat = 16

        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.usernameField)
        self.contentView.addSubview(self.passwordField)
        self.contentView.addSubview(self.footnote)
        self.contentView.addSubview(self.signInButton)
        self.contentView.addSubview(self.scanQRButton)
        self.view.addSubview(self.createAccountButton)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),

            self.contentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.contentView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.contentView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            self.contentView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor),

            self.usernameField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20),
            self.usernameField.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.usernameField.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.usernameField.heightAnchor.constraint(equalToConstant: InputField.height),

            self.passwordField.topAnchor.constraint(equalTo: self.usernameField.bottomAnchor),
            self.passwordField.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.passwordField.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.passwordField.heightAnchor.constraint(equalToConstant: InputField.height),

            self.usernameField.titleLabel.widthAnchor.constraint(equalTo: self.passwordField.titleLabel.widthAnchor).priority(.high),

            self.footnote.topAnchor.constraint(equalTo: self.passwordField.bottomAnchor, constant: 10),
            self.footnote.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
            self.footnote.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin),

            self.signInButton.topAnchor.constraint(equalTo: self.footnote.bottomAnchor, constant: margin * 2),
            self.signInButton.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
            self.signInButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin),

            self.scanQRButton.topAnchor.constraint(equalTo: self.signInButton.bottomAnchor, constant: 10),
            self.scanQRButton.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
            self.scanQRButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin),
            self.scanQRButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.createAccountButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin),
            self.createAccountButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin),
            self.createAccountButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -margin),
        ])
    }
}
