import UIKit
import SweetUIKit
import Formulaic

/// Edit user profile info. It's sent to the ID server on saveAndDismiss. Updates local session as well.
open class ProfileEditController: UIViewController {

    lazy var dataSource: FormDataSource = {
        let dataSource = FormDataSource(delegate: nil)
        let usernameValidator = TextInputValidator(minLength: 2, maxLength: 60, validationPattern: IDAPIClient.usernameValidationPattern)

        dataSource.items = [
            FormItem(title: "Username", value: User.current?.username, fieldName: "username", type: .input, textInputValidator: usernameValidator),
            FormItem(title: "Display name", value: User.current?.name, fieldName: "name", type: .input),
            FormItem(title: "About", value: User.current?.about, fieldName: "about", type: .input),
            FormItem(title: "Location", value: User.current?.location, fieldName: "location", type: .input),
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

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var changeAvatarButton: UIButton = {
        let view = UIButton(withAutoLayout: true)

        let title = NSAttributedString(string: "Change picture", attributes: [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.regular(size: 16)])
        view.setAttributedTitle(title, for: .normal)
        view.addTarget(self, action: #selector(updateAvatar), for: .touchUpInside)

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

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.addSubviewsAndConstraints()

        guard let user = User.current else { return }
        self.avatarImageView.image = user.avatar
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.toolbar)
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.changeAvatarButton)
        self.view.addSubview(self.tableView)

        self.toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.avatarImageView.cornerRadius = 40
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

    func updateAvatar() {
        let camera = UIImagePickerController()
        camera.allowsEditing = true
        camera.sourceType = .camera
        camera.cameraCaptureMode = .photo
        camera.cameraFlashMode = .off
        camera.delegate = self
        camera.showsCameraControls = true

        self.present(camera, animated: true)
    }

    func cancelAndDismiss() {
        self.dismiss(animated: true)
    }

    func saveAndDismiss() {
        // TODO: Because we are updating the local User and then passing that user as a parameter to IDAPICLIENT,
        // if the API call fails, our local copy is not rolled back. For now I'm manually rolling back username
        // as it is the only one that could fail server-side validation, but this should be applied to all
        // failures and fields.
        guard let user = User.current else { return }
        let oldUsername = user.username

        for item in self.dataSource.items {
            if item.fieldName == "username" {
                if item.validate() {
                    user.username = item.value as? String ?? User.current!.username
                } else {
                    let alert = UIAlertController.dismissableAlert(title: "Error", message: "Username is invalid! Use numbers, letters, and underscores only.")
                    self.present(alert, animated: true)
                    return
                }
            } else if item.fieldName == "name" {
                user.name = item.value as? String
            } else if item.fieldName == "about" {
                user.about = item.value as? String
            } else if item.fieldName == "location" {
                user.location = item.value as? String
            }
        }

        self.idAPIClient.updateUser(user) { success, message in
            if !success {
                user.username = oldUsername
                let alert = UIAlertController.dismissableAlert(title: "Error", message: message)
                self.present(alert, animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}

extension ProfileEditController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_: UIImagePickerController) {
        self.dismiss(animated: true)
    }

    public func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        guard let user = User.current else { return }
        guard let croppedImage = info[UIImagePickerControllerEditedImage] as? UIImage else { return }

        let scaledWidth: CGFloat = 320.0
        let scale = scaledWidth / croppedImage.size.width
        let scaledHeight = croppedImage.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: scaledWidth, height: scaledHeight))
        croppedImage.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if scaledImage != nil {
            self.avatarImageView.image = scaledImage

            self.idAPIClient.updateAvatar(scaledImage!) { _ in

            }
        }

        self.dismiss(animated: true)
    }
}

extension ProfileEditController: UITableViewDelegate {

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension ProfileEditController: UITableViewDataSource {

    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ProfileItemCell.self, for: indexPath)
        let formItem = self.dataSource.item(at: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.formItem = formItem

        return cell
    }
}

extension ProfileEditController: UIToolbarDelegate {

    public func position(for _: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
