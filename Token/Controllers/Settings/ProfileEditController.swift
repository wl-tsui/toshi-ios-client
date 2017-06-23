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
import SweetFoundation
import Formulaic
import ImagePicker

/// Edit user profile info. It's sent to the ID server on saveAndDismiss. Updates local session as well.
open class ProfileEditController: OverlayController, Editable {

    var scrollView: UIScrollView {
        return self.tableView
    }

    var keyboardWillShowSelector: Selector {
        return #selector(self.keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(self.keyboardShownNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        self.keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        self.keyboardWillHide(notification)
    }

    fileprivate var menuSheetController: MenuSheetController?

    lazy var dataSource: FormDataSource = {
        let dataSource = FormDataSource(delegate: nil)
        let usernameValidator = TextInputValidator(minLength: 2, maxLength: 60, validationPattern: IDAPIClient.usernameValidationPattern)

        dataSource.items = [
            FormItem(title: "Username", value: TokenUser.current?.username, fieldName: "username", type: .input, textInputValidator: usernameValidator),
            FormItem(title: "Display name", value: TokenUser.current?.name, fieldName: "name", type: .input),
            FormItem(title: "About", value: TokenUser.current?.about, fieldName: "about", type: .input),
            FormItem(title: "Location", value: TokenUser.current?.location, fieldName: "location", type: .input),
        ]

        return dataSource
    }()

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    fileprivate lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var changeAvatarButton: UIButton = {
        let view = UIButton(withAutoLayout: true)

        let title = NSAttributedString(string: "Change picture", attributes: [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.regular(size: 16)])
        view.setAttributedTitle(title, for: .normal)
        view.addTarget(self, action: #selector(updateAvatar), for: .touchUpInside)

        return view
    }()

    fileprivate lazy var tableView: UITableView = {
        let view = UITableView(withAutoLayout: true)

        view.backgroundColor = UIColor.clear
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.register(ProfileItemCell.self)
        view.layer.borderWidth = Theme.borderHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.navigationBarColor
        self.addSubviewsAndConstraints()

        guard let user = TokenUser.current else { return }

        if let path = user.avatarPath as String? {
            AvatarManager.shared.avatar(for: path) { image in
                self.avatarImageView.image = image
            }
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapView))
        self.view.addGestureRecognizer(tapGesture)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAndDismiss))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.saveAndDismiss))
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.registerForKeyboardNotifications()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.unregisterFromKeyboardNotifications()
    }

    fileprivate lazy var headerView: UIView = {
        let view = UIView(frame: CGRect.zero)

        view.backgroundColor = UIColor.clear
        view.addSubview(self.avatarImageView)
        view.addSubview(self.changeAvatarButton)

        let bottomBorder = UIView(withAutoLayout: true)
        view.addSubview(bottomBorder)

        bottomBorder.backgroundColor = Theme.borderColor
        bottomBorder.set(height: Theme.borderHeight)
        bottomBorder.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomBorder.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        self.avatarImageView.set(height: 80)
        self.avatarImageView.set(width: 80)
        self.avatarImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        self.changeAvatarButton.set(height: 38)
        self.changeAvatarButton.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 12).isActive = true
        self.changeAvatarButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
        self.changeAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        view.layoutIfNeeded()

        return view
    }()

    func addSubviewsAndConstraints() {
        let height = self.headerView.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height

        var headerFrame = self.headerView.frame
        headerFrame.size.height = height
        self.headerView.frame = headerFrame

        self.tableView.tableHeaderView = self.headerView

        self.view.addSubview(self.tableView)

        self.view.addSubview(self.activityIndicator)

        self.activityIndicator.set(height: 50.0)
        self.activityIndicator.set(width: 50.0)
        self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

        self.tableView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

    func updateAvatar() {
        self.menuSheetController = MenuSheetController()
        self.menuSheetController?.dismissesByOutsideTap = true
        self.menuSheetController?.hasSwipeGesture = true
        self.menuSheetController?.maxHeight = 445 - MenuSheetButtonItemViewHeight
        var itemViews = [UIView]()

        let carouselItem = AttachmentCarouselItemView(camera: Camera.cameraAvailable(), selfPortrait: false, forProfilePhoto: true, assetType: MediaAssetPhotoType)!
        carouselItem.condensed = false
        carouselItem.openEditor = true
        carouselItem.parentController = self
        carouselItem.allowCaptions = true
        carouselItem.inhibitDocumentCaptions = true
        carouselItem.suggestionContext = SuggestionContext()
        carouselItem.cameraPressed = { cameraView in
            guard AccessChecker.checkCameraAuthorizationStatus(alertDismissComlpetion: nil) == true else { return }

            self.displayCamera(from: cameraView, menu: self.menuSheetController!, carouselItem: carouselItem)
        }

        carouselItem.avatarCompletionBlock = { image in
            self.menuSheetController?.dismiss(animated: true, manual: false) {
                self.changeAvatar(to: image)
            }
        }

        itemViews.append(carouselItem)

        let galleryItem = MenuSheetButtonItemView.init(title: "Library", type: MenuSheetButtonTypeDefault, action: {
            self.menuSheetController?.dismiss(animated: true)
            self.displayMediaPicker(forFile: false, fromFileMenu: false)
        })!

        itemViews.append(galleryItem)

        carouselItem.underlyingViews = [galleryItem]

        let cancelItem = MenuSheetButtonItemView.init(title: "Cancel", type: MenuSheetButtonTypeCancel, action: {
            self.menuSheetController?.dismiss(animated: true)
        })!

        itemViews.append(cancelItem)
        self.menuSheetController?.setItemViews(itemViews)
        carouselItem.remainingHeight = MenuSheetButtonItemViewHeight * CGFloat(itemViews.count - 1)

        self.menuSheetController?.present(in: self, sourceView: self.view, animated: true)
    }

    private func displayMediaPicker(forFile _: Bool, fromFileMenu _: Bool) {

        guard AccessChecker.checkPhotoAuthorizationStatus(intent: PhotoAccessIntentRead, alertDismissCompletion: nil) else { return }
        let dismissBlock = { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }

        let showMediaPickerBlock: ((MediaAssetGroup?) -> Void) = { [unowned self] group in
            let intent: MediaAssetsControllerIntent = .setProfilePhoto // forFile ? MediaAssetsControllerIntentSendMedia : MediaAssetsControllerIntentSendMedia
            let assetsController = MediaAssetsController(assetGroup: group, intent: intent)!
            assetsController.captionsEnabled = true
            assetsController.inhibitDocumentCaptions = true
            assetsController.suggestionContext = SuggestionContext()
            assetsController.dismissalBlock = dismissBlock
            assetsController.localMediaCacheEnabled = false
            assetsController.shouldStoreAssets = false
            assetsController.shouldShowFileTipIfNeeded = false

            assetsController.avatarCompletionBlock = { image in
                assetsController.dismiss(animated: true, completion: nil)
                self.changeAvatar(to: image)
            }

            self.present(assetsController, animated: true, completion: nil)
        }

        if MediaAssetsLibrary.authorizationStatus() == MediaLibraryAuthorizationStatusNotDetermined {
            MediaAssetsLibrary.requestAuthorization(for: MediaAssetAnyType) { (_, cameraRollGroup) -> Void in

                let photoAllowed = AccessChecker.checkPhotoAuthorizationStatus(intent: PhotoAccessIntentRead, alertDismissCompletion: nil)
                let microphoneAllowed = AccessChecker.checkMicrophoneAuthorizationStatus(for: MicrophoneAccessIntentVideo, alertDismissCompletion: nil)

                if photoAllowed == false || microphoneAllowed == false {
                    return
                }

                showMediaPickerBlock(cameraRollGroup)
            }
        }

        showMediaPickerBlock(nil)
    }

    func changeAvatar(to avatar: UIImage?) {
        if let avatar = avatar as UIImage? {
            let scaledImage = avatar.resized(toHeight: 320)
            self.avatarImageView.image = scaledImage
        }
    }

    func displayCamera(from cameraView: AttachmentCameraView?, menu: MenuSheetController, carouselItem _: AttachmentCarouselItemView) {
        var controller: CameraController
        let screenSize = TGScreenSize()

        if let previewView = cameraView?.previewView() as CameraPreviewView? {
            controller = CameraController(camera: previewView.camera, previewView: previewView, intent: CameraControllerAvatarIntent)!
        } else {
            controller = CameraController()
        }

        controller.isImportant = true
        controller.shouldStoreCapturedAssets = true
        controller.allowCaptions = true

        let controllerWindow = CameraControllerWindow(parentController: self, contentController: controller)
        controllerWindow?.isHidden = false

        controllerWindow?.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)

        var startFrame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: screenSize.height)

        if let cameraView = cameraView as AttachmentCameraView?, let frame = cameraView.previewView().frame as CGRect? {
            startFrame = controller.view.convert(frame, from: cameraView)
        }

        cameraView?.detachPreviewView()
        controller.beginTransitionIn(from: startFrame)

        controller.beginTransitionOut = {

            if let cameraView = cameraView as AttachmentCameraView? {

                cameraView.willAttachPreviewView()
                return controller.view.convert(cameraView.frame, from: cameraView.superview)
            }

            return CGRect.zero
        }

        controller.finishedTransitionOut = {
            cameraView?.attachPreviewView(animated: true)
        }

        controller.finishedWithPhoto = { resultImage, _, _ in

            menu.dismiss(animated: true)
            self.changeAvatar(to: resultImage)
        }
    }

    func cancelAndDismiss() {
        self.navigationController?.popViewController(animated: true)
    }

    func saveAndDismiss() {
        guard let user = TokenUser.current else { return }

        var username = ""
        var name = ""
        var about = ""
        var location = ""

        for item in self.dataSource.items {
            if item.fieldName == "username" {
                if item.validate() {
                    username = item.value as? String ?? TokenUser.current!.username
                } else {
                    let alert = UIAlertController.dismissableAlert(title: "Error", message: "Username is invalid! Use numbers, letters, and underscores only.")
                    self.present(alert, animated: true)
                    return
                }
            } else if item.fieldName == "name" {
                name = item.value as? String ?? ""
            } else if item.fieldName == "about" {
                about = item.value as? String ?? ""
            } else if item.fieldName == "location" {
                location = item.value as? String ?? ""
            }
        }

        self.view.endEditing(true)
        self.activityIndicator.startAnimating()

        let userDict: [String: Any] = [
            TokenUser.Constants.address: user.address,
            TokenUser.Constants.paymentAddress: user.paymentAddress,
            TokenUser.Constants.username: username,
            TokenUser.Constants.about: about,
            TokenUser.Constants.location: location,
            TokenUser.Constants.name: name,
            TokenUser.Constants.avatar: user.avatarPath,
            TokenUser.Constants.isApp: user.isApp,
            TokenUser.Constants.verified: user.verified,
        ]

        self.idAPIClient.updateUser(userDict) { userUpdated, message in

            let cachedAvatar = AvatarManager.shared.cachedAvatar(for: user.avatarPath)

            if let image = self.avatarImageView.image as UIImage?, image != cachedAvatar {

                self.idAPIClient.updateAvatar(image) { avatarUpdated in
                    let success = userUpdated == true && avatarUpdated == true

                    self.completeEdit(success: success, message: message)
                }
            } else {
                self.completeEdit(success: userUpdated, message: message)
            }
        }
    }

    fileprivate func completeEdit(success: Bool, message: String?) {
        self.activityIndicator.stopAnimating()

        if success == true {
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController.dismissableAlert(title: "Error", message: message ?? "Something went wrong")
            self.present(alert, animated: true)
        }
    }

    @objc private func didTapView(sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            self.becomeFirstResponder()
        }
    }

    fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
        // need to initialize with large style which is available only white, thus need to set color later
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = Theme.lightGreyTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }()
}

extension ProfileEditController: ImagePickerDelegate {

    public func wrapperDidPress(_: ImagePickerController, images _: [UIImage]) {
    }

    public func doneButtonDidPress(_: ImagePickerController, images: [UIImage]) {
        guard let image = images.first else { return }

        self.changeAvatar(to: image)
    }

    public func cancelButtonDidPress(_: ImagePickerController) {
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
        cell.selectionStyle = .none
        cell.formItem = formItem

        return cell
    }
}
