
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
import NoChat
import MobileCoreServices
import ImagePicker
import AVFoundation

final class ChatController: OverlayController, UITableViewDataSource {

    private static let subcontrolsViewWidth: CGFloat = 228.0

    fileprivate lazy var viewModel: ChatViewModel = {
        return ChatViewModel(output: self, thread: self.thread)
    }()

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let messages = self.viewModel.messageModels as [MessageModel]? else { return 0 }

        return messages.count
    }

    fileprivate lazy var imagesCache: NSCache<NSString, UIImage> = {
         return NSCache<NSString, UIImage>()

    }()

    private(set) lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.estimatedRowHeight = 64.0
        view.allowsSelection = true
        view.dataSource = self
        view.tableFooterView = UIView()
        view.separatorStyle = .none
        view.keyboardDismissMode = .interactive

        view.register(ImageMessageCell.self)
        view.register(TextMessageCell.self)
        view.register(PaymentMessageCell.self)

        return view
    }()

    fileprivate lazy var textInputViewBottom: NSLayoutConstraint = {
        self.textInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    }()

    fileprivate lazy var textInputView: ChatInputTextPanel = {
        let view = ChatInputTextPanel(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var textInputViewHeight: NSLayoutConstraint = {
        self.textInputView.heightAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight)
    }()

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate lazy var disposable: SMetaDisposable = {
        let disposable = SMetaDisposable()
        return disposable
    }()

    fileprivate lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
    }()

    fileprivate var textLayoutQueue = DispatchQueue(label: "com.tokenbrowser.token.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))

    fileprivate lazy var avatarImageView: AvatarImageView = {
        let avatar = AvatarImageView(image: UIImage())
        avatar.bounds.size = CGSize(width: 34, height: 34)
        avatar.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showContactProfile))
        avatar.addGestureRecognizer(tap)

        return avatar
    }()

    fileprivate var menuSheetController: MenuSheetController?

    private(set) var thread: TSThread

    fileprivate lazy var ethereumPromptView: ChatsFloatingHeaderView = {
        let view = ChatsFloatingHeaderView(withAutoLayout: true)
        view.delegate = self

        return view
    }()

    fileprivate var buttons: [SofaMessage.Button] = [] {
        didSet {
            self.adjustToNewButtons()
        }
    }
    
    fileprivate lazy var controlsViewDelegateDatasource: ControlsViewDelegateDataSource = {
        let controlsViewDelegateDatasource = ControlsViewDelegateDataSource()

        controlsViewDelegateDatasource.actionDelegate = self

        return controlsViewDelegateDatasource
    }()
    
    fileprivate lazy var subcontrolsViewDelegateDatasource: SubcontrolsViewDelegateDataSource = {
        let subcontrolsViewDelegateDatasource = SubcontrolsViewDelegateDataSource()

        subcontrolsViewDelegateDatasource.actionDelegate = self

        return subcontrolsViewDelegateDatasource
    }()

    fileprivate lazy var controlsViewHeightConstraint: NSLayoutConstraint = {
        self.controlsView.heightAnchor.constraint(equalToConstant: 0)
    }()

    fileprivate lazy var subcontrolsViewHeightConstraint: NSLayoutConstraint = {
        self.subcontrolsView.heightAnchor.constraint(equalToConstant: 0)
    }()

    fileprivate lazy var controlsView: ControlsCollectionView = {
        let view = ControlsCollectionView()

        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(ControlCell.self)
        view.delegate = self.controlsViewDelegateDatasource
        view.dataSource = self.controlsViewDelegateDatasource

        return view
    }()

    fileprivate lazy var subcontrolsView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(SubcontrolCell.self)
        view.delegate = self.subcontrolsViewDelegateDatasource
        view.dataSource = self.subcontrolsViewDelegateDatasource

        return view
    }()

    fileprivate var isVisible: Bool = false

    fileprivate var textInputHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

    let buttonMargin: CGFloat = 10

    fileprivate var buttonsHeight: CGFloat = 0 {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

    fileprivate var heightOfKeyboard: CGFloat = 0 {
        didSet {
            if self.isVisible, heightOfKeyboard != oldValue {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                }, completion: nil)

                self.updateConstraints()
            }
        }
    }

    fileprivate func adjustToPaymentState(_ state: TSInteraction.PaymentState, at indexPath: IndexPath) {
        guard let message = self.viewModel.messageModels[indexPath.row] as MessageModel?, message.type == .paymentRequest || message.type == .payment, let signalMessage = message.signalMessage as TSMessage? else { return }

        signalMessage.paymentState = state
        signalMessage.save()

        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }

    fileprivate func image(for message: MessageModel) -> UIImage {
        var image = UIImage()
        if let cachedImage = self.imagesCache.object(forKey: message.identifier as NSString) as UIImage? {
            image = cachedImage
        } else if let messageImage = message.image as UIImage? {
            let maxWidth: CGFloat = UIScreen.main.bounds.width * 0.5

            let maxSize = CGSize(width: maxWidth, height: UIScreen.main.bounds.height)
            let imageFitSize = TGFitSizeF(messageImage.size, maxSize)

            image = ScaleImageToPixelSize(messageImage, imageFitSize)

            self.imagesCache.setObject(image, forKey: message.identifier as NSString)
        }

        return image
    }

    fileprivate func imageMessageCell(for message: MessageModel, at indexPath: IndexPath) -> ImageMessageCell {
        let cell = tableView.dequeue(ImageMessageCell.self, for: indexPath)
        cell.isOutgoing = message.isOutgoing
        cell.setup(with: self.image(for: message))
        cell.tapDelegate = self

        if let identifier = self.viewModel.contact?.avatarPath as String?, message.isOutgoing == false {
            AvatarManager.shared.avatar(for: identifier, completion: { image, _ in
                cell.avatarImageView.image = image
            })
        }

        return cell
    }

    fileprivate func textMessageCell(for message: MessageModel, at indexPath: IndexPath) -> TextMessageCell {
        let cell = tableView.dequeue(TextMessageCell.self, for: indexPath)
        cell.textView.attributedText = nil
        cell.textView.text = message.text
        cell.isOutgoing = message.isOutgoing

        if let identifier = self.viewModel.contact?.avatarPath as String?, message.isOutgoing == false {
            AvatarManager.shared.avatar(for: identifier, completion: { image, _ in
                cell.avatarImageView.image = image
            })
        }

        return cell
    }

    fileprivate func paymentMessageCell(for message: MessageModel, at indexPath: IndexPath) -> PaymentMessageCell {
        let cell = tableView.dequeue(PaymentMessageCell.self, for: indexPath)
        cell.titleLabel.text = message.title
        cell.subTitleLabel.text = message.subtitle
        cell.detailsLabel.text = message.text

        cell.isOutgoing = message.isOutgoing
        cell.setup(with: message)

        if let identifier = self.viewModel.contact?.avatarPath as String?, message.isOutgoing == false {
            AvatarManager.shared.avatar(for: identifier, completion: { image, _ in
                cell.avatarImageView.image = image
            })
        }

        cell.delegate = self

        return cell
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = viewModel.messageModels.element(at: indexPath.item) as MessageModel? else { return UITableViewCell() }

        switch message.type {
        case .image:
            return self.imageMessageCell(for: message, at: indexPath)
        case .simple:
            return self.textMessageCell(for: message, at: indexPath)
        case .payment, .paymentRequest:
            return self.paymentMessageCell(for: message, at: indexPath)

        default:
            break
        }
        
        return UITableViewCell()
    }

    fileprivate func messageAction(for indexPath: IndexPath, message: MessageModel) -> MessageAction {
        return { type in
            
            let paymentState: TSInteraction.PaymentState = (type == .approve) ? .pendingConfirmation : .rejected
            
            self.adjustToPaymentState(paymentState, at: indexPath)
            
            guard type == .approve, let paymentRequest = message.sofaWrapper as? SofaPaymentRequest else { return }
            
            self.showActivityIndicator()
            
            self.viewModel.interactor.sendPayment(in: paymentRequest.value, completion: { (success: Bool) in
                let state: TSInteraction.PaymentState = success ? .approved : .failed
                self.adjustToPaymentState(state, at: indexPath)
            })
        }
    }
    
    fileprivate func updateConstraints() {
        self.textInputViewBottom.constant = self.heightOfKeyboard < -self.textInputHeight ? self.heightOfKeyboard + self.textInputHeight + self.buttonsHeight : 0
        
        self.textInputViewHeight.constant = self.textInputHeight
        
        self.controlsViewHeightConstraint.constant = self.buttonsHeight
        self.keyboardAwareInputView.height = self.buttonsHeight + self.textInputHeight
        self.keyboardAwareInputView.invalidateIntrinsicContentSize()
        
        self.view.layoutIfNeeded()
    }
    
    // MARK: - Init
    
    init(thread: TSThread) {
        self.thread = thread
        
        super.init(nibName: nil, bundle: nil)
        
        self.hidesBottomBarWhenPushed = true
        self.title = thread.cachedContactIdentifier
        
        self.registerNotifications()
    }
    
    required init?(coder _: NSCoder) {
        fatalError()
    }
    
    fileprivate func adjustToNewButtons() {
        DispatchQueue.main.async {
            
            self.controlsView.isHidden = true
            self.updateSubcontrols(with: nil)
            self.controlsViewHeightConstraint.constant = self.buttons.count > 0 ? 250 : 0
            self.controlsViewDelegateDatasource.items = self.buttons
            self.controlsView.reloadData()
            
            let duration = self.buttons.count > 0 ? 0.0 : 0.3
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                self.controlsView.layoutIfNeeded()
            }) { completed in

            }
            
            var height: CGFloat = 0
            
            let controlCells = self.controlsView.visibleCells.flatMap { cell in cell as? ControlCell }
            
            for controlCell in controlCells {
                height = max(height, controlCell.frame.maxY)
            }
            
            self.controlsViewHeightConstraint.constant = 0
            UIView.animate(withDuration: 0,delay: 0, animations: {
                self.controlsView.layoutIfNeeded()
            }, completion: { completed in

                if completed {
                    self.controlsView.isHidden = false

                    self.buttonsHeight = height > 0 ? height + (2 * self.buttonMargin) : 0

                    guard height > 0 else { return }
                    self.controlsViewHeightConstraint.constant = height

                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                        self.controlsView.layoutIfNeeded()
                    }) { completed in
                        self.scrollToBottom(animated: true)
                    }

                    self.controlsView.deselectButtons()
                }
            })
        }
    }
    
    fileprivate func scrollToBottom(animated: Bool = true) {
        let numberOfItems = self.tableView.numberOfRows(inSection: 0)
        guard numberOfItems > 0 else { return }
        
        let lastIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }
    
    // MARK: View life-cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addSubviewsAndConstraints()
        
        self.viewModel.fetchAndUpdateBalance(completion: { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                Navigator.presentModally(alertController)
            } else {
                self.set(balance: balance)
            }
        })
    }
    
    fileprivate func addSubviewsAndConstraints() {
        
        self.view.addSubview(self.textInputView)
        
        NSLayoutConstraint.activate([
            self.textInputView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.textInputView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            
            self.textInputViewBottom,
            self.textInputViewHeight,
            ])
        
        self.view.addSubview(self.controlsView)
        
        self.controlsViewHeightConstraint.isActive = true
        self.controlsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.controlsView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true
        self.controlsView.bottomAnchor.constraint(equalTo: self.textInputView.topAnchor).isActive = true
        self.controlsViewDelegateDatasource.controlsCollectionView = self.controlsView
        
        self.hideSubcontrolsMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        self.view.backgroundColor = Theme.messageViewBackgroundColor
        
        self.setupActivityIndicator()
        
        self.textInputView.delegate = self
        
        self.view.addSubview(self.ethereumPromptView)
        self.ethereumPromptView.heightAnchor.constraint(equalToConstant: ChatsFloatingHeaderView.height).isActive = true
        self.ethereumPromptView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.ethereumPromptView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.ethereumPromptView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.view.addSubview(self.tableView)
        self.tableView.topAnchor.constraint(equalTo: self.ethereumPromptView.bottomAnchor).isActive = true
        self.tableView.left(to: self.view)
        self.tableView.right(to: self.view)
        self.tableView.bottomToTop(of: self.controlsView)
        
        self.view.addSubview(self.subcontrolsView)
        
        self.subcontrolsViewHeightConstraint.isActive = true
        self.subcontrolsView.width(ChatController.subcontrolsViewWidth)
        self.subcontrolsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.subcontrolsView.bottomAnchor.constraint(equalTo: self.controlsView.topAnchor, constant: self.buttonMargin).isActive = true
        self.subcontrolsViewDelegateDatasource.subcontrolsCollectionView = self.subcontrolsView
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.avatarImageView)
    }
    
    func keyboardDidHide() {
        self.becomeFirstResponder()
    }
    
    func keyboardWillShow() {
        if self.textInputView.inputField.isFirstResponder() == true {
            self.scrollToBottom(animated: false)
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController == nil
    }
    
    fileprivate func checkMicrophoneAccess() {
        if AVAudioSession.sharedInstance().recordPermission().contains(.undetermined) {
            
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.isVisible = true
        
        self.viewModel.reloadDraft(completion: { placeholder in
            self.textInputView.text = placeholder
        })
        
        self.tabBarController?.tabBar.isHidden = true
        
        self.avatarImageView.image = self.viewModel.thread.image()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
        self.title = self.viewModel.thread.cachedContactIdentifier
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.isVisible = false
        self.heightOfKeyboard = 0
        
        self.viewModel.saveDraftIfNeeded(inputViewText: self.textInputView.text)
        
        self.viewModel.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
    }
    
    @objc
    fileprivate func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.set(balance: balance)
    }
    
    fileprivate func set(balance: NSDecimalNumber) {
        self.ethereumPromptView.balance = balance
    }
    
    // Mark: Handle new messages
    
    fileprivate func showFingerprint(with _: Data, signalId _: String) {
        // Postpone this for now

        //        let builder = OWSFingerprintBuilder(storageManager: self.storageManager, contactsManager: self.contactsManager)
        //        let fingerprint = builder.fingerprint(withTheirSignalId: signalId, theirIdentityKey: identityKey)
        //
        //        let fingerprintController = FingerprintViewController(fingerprint: fingerprint)
        //        self.present(fingerprintController, animated: true)
    }
    
    fileprivate func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        //notificationCenter.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)
    }
    
    // MARK: - Control handling
    
    fileprivate func didTapControlButton(_ button: SofaMessage.Button) {
        if let action = button.action as? String {
            let prefix = "Webview::"
            guard action.hasPrefix(prefix) else { return }
            guard let actionPath = action.components(separatedBy: prefix).last,
                let url = URL(string: actionPath) else { return }
            
            let sofaWebController = SOFAWebController()
            sofaWebController.load(url: url)
            
            self.navigationController?.pushViewController(sofaWebController, animated: true)
        } else if button.value != nil {
            self.buttons = []
            let command = SofaCommand(button: button)
            self.controlsViewDelegateDatasource.controlsCollectionView?.isUserInteractionEnabled = false
            self.viewModel.interactor.sendMessage(sofaWrapper: command)
        }
    }
    
    @objc
    fileprivate func showContactProfile(_ sender: UITapGestureRecognizer) {
        if let contact = self.viewModel.contact as TokenUser?, sender.state == .ended {
            let contactController = ContactController(contact: contact)
            self.navigationController?.pushViewController(contactController, animated: true)
        }
    }
    
    func sendPayment(with parameters: [String: Any]) {
        self.showActivityIndicator()
        self.viewModel.interactor.sendPayment(with: parameters)
    }
    
    //MARK: - Camera and picker
    fileprivate func displayCamera(from cameraView: AttachmentCameraView?, menu: MenuSheetController, carouselItem _: AttachmentCarouselItemView) {
        var controller: CameraController
        let screenSize = TGScreenSize()
        
        if let previewView = cameraView?.previewView() as CameraPreviewView? {
            controller = CameraController(camera: previewView.camera, previewView: previewView, intent: CameraControllerGenericIntent)!
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
            if let image = resultImage as UIImage? {
                self.viewModel.interactor.send(image: image)
            }
        }
        
        controller.finishedWithVideo = { videoURL, _, _, _, _, _, _ in
            defer { menu.dismiss(animated: false) }
            
            self.showActivityIndicator()
            
            guard let videoURL = videoURL else { return }
            self.viewModel.interactor.sendVideo(with: videoURL)
        }
    }
    
    fileprivate func displayMediaPicker(forFile _: Bool, fromFileMenu _: Bool) {
        
        guard AccessChecker.checkPhotoAuthorizationStatus(intent: PhotoAccessIntentRead, alertDismissCompletion: nil) else { return }
        let dismissBlock = { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
        
        let showMediaPickerBlock: ((MediaAssetGroup?) -> Void) = { [unowned self] group in
            let intent: MediaAssetsControllerIntent = .sendMedia
            let assetsController = MediaAssetsController(assetGroup: group, intent: intent)!
            assetsController.captionsEnabled = true
            assetsController.inhibitDocumentCaptions = true
            assetsController.suggestionContext = SuggestionContext()
            assetsController.dismissalBlock = dismissBlock
            assetsController.localMediaCacheEnabled = false
            assetsController.shouldStoreAssets = false
            assetsController.shouldShowFileTipIfNeeded = false
            
            assetsController.completionBlock = { signals in
                
                assetsController.dismiss(animated: true, completion: nil)
                
                if let signals = signals as? [SSignal] {
                    self.viewModel.interactor.asyncProcess(signals: signals)
                }
            }
            
            Navigator.presentModally(assetsController)
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
}

extension ChatController: PaymentMessageCellDelegate {
    func didTapApprovePaymentCell(_ cell: PaymentMessageCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) as IndexPath? else { return }
        guard let message = self.viewModel.messageModels.element(at: indexPath.row) as MessageModel? else { return }

        self.adjustToPaymentState(.pendingConfirmation, at: indexPath)

        guard let paymentRequest = message.sofaWrapper as? SofaPaymentRequest else { return }

        self.showActivityIndicator()

        self.viewModel.interactor.sendPayment(in: paymentRequest.value, completion: { (success: Bool) in
            let state: TSInteraction.PaymentState = success ? .approved : .failed
            self.adjustToPaymentState(state, at: indexPath)
        })
    }

    func didTapRejectPaymentCell(_ cell: PaymentMessageCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) as IndexPath? else { return }

        self.adjustToPaymentState(.rejected, at: indexPath)
    }
}

extension ChatController: ImagesViewControllerDismissDelegate {
    
    func imagesAreDismissed(from indexPath: IndexPath) {
        self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: false)
    }
}

extension ChatController: ImageMessageCellDelegate {
    func didTapImage(in cell: ImageMessageCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) as IndexPath? else { return }

        let controller = ImagesViewController(messages: self.viewModel.messageModels, initialIndexPath: indexPath)
        controller.dismissDelegate = self
        controller.title = self.title
        controller.transitioningDelegate = self
        Navigator.presentModally(controller)
    }
}

extension ChatController: ChatViewModelOutput {
    func didReload() {
        for message in self.viewModel.messages {
            if let paymentRequest = message.sofaWrapper as? SofaPaymentRequest {
                message.fiatValueString = EthereumConverter.fiatValueStringWithCode(forWei: paymentRequest.value, exchangeRate: EthereumAPIClient.shared.exchangeRate)
                message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: paymentRequest.value)
            } else if let payment = message.sofaWrapper as? SofaPayment {
                message.fiatValueString = EthereumConverter.fiatValueStringWithCode(forWei: payment.value, exchangeRate: EthereumAPIClient.shared.exchangeRate)
                message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: payment.value)
            }
        }

        self.sendGreetingTriggerIfNeeded()

        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.scrollToBottom(animated: false)
        }
    }
    
    fileprivate func sendGreetingTriggerIfNeeded() {
        if let contact = self.viewModel.contact as TokenUser?, contact.isApp && self.viewModel.messages.isEmpty {
            // If contact is an app, and there are no messages between current user and contact
            // we send the app an empty regular sofa message. This ensures that Signal won't display it,
            // but at the same time, most bots will reply with a greeting.
            self.viewModel.interactor.sendMessage(sofaWrapper: SofaMessage(body: ""))
        }
    }
}

extension ChatController: ChatInteractorOutput {
    
    func didHandleSofaMessage(with buttons: [SofaMessage.Button]) {
        self.buttons = buttons
    }

    func didCatchError(_ error: Error) {
        self.hideActivityIndicator()
        
        let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: error.localizedDescription)
        Navigator.presentModally(alert)
    }
    
    func didFinishRequest() {
        self.hideActivityIndicator()
    }
}

extension ChatController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

extension ChatController: ChatInputTextPanelDelegate {
    func inputPanel(_: NOCChatInputPanel, willChangeHeight _: CGFloat, duration _: TimeInterval, animationCurve _: Int32) {
    }
    
    func inputTextPanel(_: ChatInputTextPanel, requestSendText text: String) {
        let wrapper = SofaMessage(content: ["body": text])
        
        self.viewModel.interactor.sendMessage(sofaWrapper: wrapper)
    }
    
    func inputTextPanelRequestSendAttachment(_: ChatInputTextPanel) {
        self.view.layoutIfNeeded()
        
        self.view.endEditing(true)
        
        self.menuSheetController = MenuSheetController()
        self.menuSheetController?.dismissesByOutsideTap = true
        self.menuSheetController?.hasSwipeGesture = true
        self.menuSheetController?.maxHeight = 445 - MenuSheetButtonItemViewHeight
        var itemViews = [UIView]()
        
        self.checkMicrophoneAccess()
        
        let carouselItem = AttachmentCarouselItemView(camera: Camera.cameraAvailable(), selfPortrait: false, forProfilePhoto: false, assetType: MediaAssetAnyType)!
        carouselItem.condensed = false
        carouselItem.parentController = self
        carouselItem.allowCaptions = true
        carouselItem.inhibitDocumentCaptions = true
        carouselItem.suggestionContext = SuggestionContext()
        carouselItem.cameraPressed = { cameraView in
            guard AccessChecker.checkCameraAuthorizationStatus(alertDismissComlpetion: nil) == true else { return }
            
            self.displayCamera(from: cameraView, menu: self.menuSheetController!, carouselItem: carouselItem)
        }
        
        carouselItem.sendPressed = { [unowned self] currentItem, asFiles in
            self.menuSheetController?.dismiss(animated: true, manual: false) {
                
                let intent: MediaAssetsControllerIntent = asFiles == true ? .sendFile : .sendMedia
                
                if let signals = MediaAssetsController.resultSignals(selectionContext: carouselItem.selectionContext, editingContext: carouselItem.editingContext, intent: intent, currentItem: currentItem, storeAssets: true, useMediaCache: true) as? [SSignal] {
                    self.viewModel.interactor.asyncProcess(signals: signals)
                }
            }
        }
        
        itemViews.append(carouselItem)
        
        let galleryItem = MenuSheetButtonItemView.init(title: "Photo or Video", type: MenuSheetButtonTypeDefault, action: { [unowned self] in
            
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
    
    func inputTextPanelDidChangeHeight(_ height: CGFloat) {
        self.textInputHeight = height
    }
}

extension ChatController: ImagePickerDelegate {
    func cancelButtonDidPress(_: ImagePickerController) {
        self.dismiss(animated: true)
    }
    
    func doneButtonDidPress(_: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true) {
            for image in images {
                self.viewModel.interactor.send(image: image)
            }
        }
    }
    
    func wrapperDidPress(_: ImagePickerController, images _: [UIImage]) {
    }
}

extension ChatController: ChatsFloatingHeaderViewDelegate {
    
    func messagesFloatingView(_: ChatsFloatingHeaderView, didPressRequestButton _: UIButton) {
        let paymentRequestController = PaymentRequestController()
        paymentRequestController.delegate = self
        Navigator.presentModally(paymentRequestController)
    }
    
    func messagesFloatingView(_: ChatsFloatingHeaderView, didPressPayButton _: UIButton) {
        self.view.layoutIfNeeded()
        self.controlsViewHeightConstraint.constant = 0.0
        
        let paymentSendController = PaymentSendController()
        paymentSendController.delegate = self
        
        Navigator.presentModally(paymentSendController)
    }
}

extension ChatController: PaymentSendControllerDelegate {
    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let valueInWei = valueInWei else { return }
        
        self.showActivityIndicator()
        self.viewModel.interactor.sendPayment(in: valueInWei)
    }
}

extension ChatController: PaymentRequestControllerDelegate {
    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }
        
        guard let valueInWei = valueInWei else { return }
        
        let request: [String: Any] = [
            "body": "Request for \(EthereumConverter.balanceAttributedString(forWei: valueInWei, exchangeRate: EthereumAPIClient.shared.exchangeRate).string).",
            "value": valueInWei.toHexString,
            "destinationAddress": Cereal.shared.paymentAddress,
            ]
        
        let paymentRequest = SofaPaymentRequest(content: request)
        
        self.viewModel.interactor.sendMessage(sofaWrapper: paymentRequest)
    }
}

extension ChatController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is ImagesViewController ? ImagesViewControllerTransition(operation: .present) : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is ImagesViewController ? ImagesViewControllerTransition(operation: .dismiss) : nil
    }
    
    func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        if let imagesViewController = presentedViewController as? ImagesViewController, let transition = imagesViewController.interactiveTransition {
            return transition
        }
        
        return nil
    }
}

extension ChatController: KeyboardAwareAccessoryViewDelegate {
    func inputView(_: KeyboardAwareInputAccessoryView, shouldUpdatePosition keyboardOriginYDistance: CGFloat) {
        self.heightOfKeyboard = keyboardOriginYDistance
    }
    
    override var inputAccessoryView: UIView? {
        self.keyboardAwareInputView.isUserInteractionEnabled = false
        return self.keyboardAwareInputView
    }
}

extension ChatController: ControlViewActionDelegate {
    func controlsCollectionViewDidSelectControl(_ button: SofaMessage.Button) {
        switch button.type {
        case .button:
            self.didTapControlButton(button)
        case .group:
            self.updateSubcontrols(with: button)
        }
    }
    
    func updateSubcontrols(with button: SofaMessage.Button?) {
        switch self.viewModel.displayState(for: button) {
        case .show:
            self.showSubcontrolsMenu(button: button!)
        case .hide:
            self.hideSubcontrolsMenu()
        case .hideAndShow:
            self.hideSubcontrolsMenu {
                self.showSubcontrolsMenu(button: button!)
            }
        case .doNothing:
            break
        }
    }
    
    func hideSubcontrolsMenu(completion: (() -> Void)? = nil) {
        self.subcontrolsViewDelegateDatasource.items = []
        self.viewModel.currentButton = nil
        
        self.subcontrolsViewHeightConstraint.constant = 0
        self.subcontrolsView.backgroundColor = .clear
        self.subcontrolsView.isHidden = true
        
        self.controlsView.deselectButtons()
        
        self.view.layoutIfNeeded()
        
        completion?()
    }
    
    func showSubcontrolsMenu(button: SofaMessage.Button, completion: (() -> Void)? = nil) {
        self.controlsView.deselectButtons()
        self.subcontrolsViewHeightConstraint.constant = self.view.frame.height
        self.subcontrolsView.isHidden = true
        
        let controlCell = SubcontrolCell(frame: .zero)
        var maxWidth: CGFloat = 0.0
        
        button.subcontrols.forEach { button in
            controlCell.button.setTitle(button.label, for: .normal)
            let bounds = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 38)
            maxWidth = max(maxWidth, controlCell.button.titleLabel!.textRect(forBounds: bounds, limitedToNumberOfLines: 1).width + controlCell.buttonInsets.left + controlCell.buttonInsets.right)
        }
        
        self.subcontrolsViewDelegateDatasource.items = button.subcontrols

        self.viewModel.currentButton = button
        
        self.subcontrolsView.reloadData()
        
        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            var height: CGFloat = 0
            
            for cell in self.subcontrolsView.visibleCells {
                height += cell.frame.height
            }
            
            self.subcontrolsViewHeightConstraint.constant = height
            self.subcontrolsView.isHidden = false
            self.view.layoutIfNeeded()
            
            completion?()
        }
    }
}
