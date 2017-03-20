import UIKit
import SweetUIKit
import Formulaic

/// Edit user profile info. It's sent to the ID server on saveAndDismiss. Updates local session as well.
open class ProfileEditController: UIViewController {

    lazy var dataSource: FormDataSource = {
        let dataSource = FormDataSource(delegate: nil)

        dataSource.items = [
            FormItem(title: "Username", value: User.current?.username ?? "", fieldName: "username", type: .input),
            FormItem(title: "Display name", value: User.current?.name ?? "", fieldName: "name", type: .input),
            FormItem(title: "About", value: User.current?.about ?? "", fieldName: "about", type: .input),
            FormItem(title: "Location", value: User.current?.location ?? "", fieldName: "location", type: .input),
        ]

        return dataSource
    }()

    var idAPIClient: IDAPIClient

    lazy var toolbar: UIToolbar = {
        let view = UIToolbar(withAutoLayout: true)
        view.barTintColor = Theme.tintColor
        view.tintColor = Theme.lightTextColor
        view.delegate = self

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let title = UIBarButtonItem(title: "Edit profile", style: .plain, target: nil, action: nil)
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAndDismiss))
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveAndDismiss))

        view.items = [cancel, space, title, space, done]

        return view
    }()

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.clipsToBounds = true

        return view
    }()

    lazy var changeAvatarButton: UIButton = {
        let view = UIButton(withAutoLayout: true)

        let title = NSAttributedString(string: "Change picture", attributes: [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.regular(size: 16)])
        view.setAttributedTitle(title, for: .normal)

        return view
    }()

    lazy var tableView: UITableView = {
        let view = UITableView(withAutoLayout: true)
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.register(ProfileItemCell.self)
        view.layer.borderWidth = Theme.borderHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = false

        return view
    }()

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(idAPIClient: IDAPIClient) {
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

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.addSubviewsAndConstraints()
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.toolbar)
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.changeAvatarButton)
        self.view.addSubview(self.tableView)

        self.toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.avatarImageView.layer.cornerRadius = 40
        self.avatarImageView.set(height: 80)
        self.avatarImageView.set(width: 80)
        self.avatarImageView.topAnchor.constraint(equalTo: self.toolbar.bottomAnchor, constant: 24).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.changeAvatarButton.set(height: 38)
        self.changeAvatarButton.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 12).isActive = true
        self.changeAvatarButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.tableView.set(height: CGFloat(44 * self.dataSource.count))
        self.tableView.topAnchor.constraint(equalTo: self.changeAvatarButton.bottomAnchor, constant: 24).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }

    func cancelAndDismiss() {
        self.dismiss(animated: true)
    }

    func saveAndDismiss() {
        var username = ""
        var name: String?
        var location: String?
        var about: String?

        for item in self.dataSource.items {
            if item.fieldName == "username" {
                username = item.value as? String ?? User.current!.username
            } else if item.fieldName == "name" {
                name = item.value as? String
            } else if item.fieldName == "about" {
                about = item.value as? String
            } else if item.fieldName == "location" {
                location = item.value as? String
            }
        }

        let user = User(address: User.current!.address, paymentAddress: User.current!.paymentAddress, username: username, name: name, about: about, location: location)
        self.idAPIClient.updateUser(user) { success in
            if !success {
                let alert = UIAlertController.dismissableAlert(title: "Error", message: "Could not update user!")
                self.present(alert, animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}

extension ProfileEditController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension ProfileEditController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ProfileItemCell.self, for: indexPath)
        let formItem = self.dataSource.item(at: indexPath)

        cell.formItem = formItem

        return cell
    }
}

extension ProfileEditController: UIToolbarDelegate {

    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
