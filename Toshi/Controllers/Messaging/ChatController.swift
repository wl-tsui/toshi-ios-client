
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

final class ChatController: OverlayController {

    // static vars
    fileprivate static let subcontrolsViewWidth: CGFloat = 228.0
    fileprivate static let buttonMargin: CGFloat = 10

    // properties
    private(set) var thread: TSThread

    fileprivate var textLayoutQueue = DispatchQueue(label: "com.tokenbrowser.token.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))
    fileprivate var menuSheetController: MenuSheetController?

    fileprivate var isVisible: Bool = false

    // computed properties
    override var canBecomeFirstResponder: Bool {
        return presentedViewController == nil
    }

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    // observed properties
    fileprivate var buttons: [SofaMessage.Button] = [] {
        didSet {
            self.adjustToNewButtons()
        }
    }

    fileprivate var textInputHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

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

    // lazy vars
    fileprivate lazy var viewModel: ChatViewModel = {
        ChatViewModel(output: self, thread: self.thread)
    }()

    fileprivate lazy var imagesCache: NSCache<NSString, UIImage> = {
        NSCache<NSString, UIImage>()
    }()

    fileprivate lazy var disposable: SMetaDisposable = {
        let disposable = SMetaDisposable()

        return disposable
    }()

    // lazy views

    fileprivate lazy var avatarImageView: AvatarImageView = {
        let avatar = AvatarImageView(image: UIImage())
        avatar.bounds.size = CGSize(width: 34, height: 34)
        avatar.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.showContactProfile))
        avatar.addGestureRecognizer(tap)

        return avatar
    }()

    fileprivate lazy var ethereumPromptView: ChatsFloatingHeaderView = {
        let view = ChatsFloatingHeaderView(withAutoLayout: true)
        view.delegate = self

        return view
    }()

    fileprivate lazy var networkView: ActiveNetworkView = {
        self.defaultActiveNetworkView()
    }()

    private(set) lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Theme.viewBackgroundColor
        view.estimatedRowHeight = 64.0
        view.allowsSelection = true
        view.dataSource = self
        view.delegate = self
        view.tableFooterView = UIView()
        view.separatorStyle = .none
        view.keyboardDismissMode = .interactive
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)

        view.contentInset = UIEdgeInsets(top: ChatsFloatingHeaderView.height + 64.0, left: 0, bottom: 0, right: 0)

        view.register(MessagesImageCell.self)
        view.register(MessagesPaymentCell.self)
        view.register(MessagesTextCell.self)

        return view
    }()

    fileprivate lazy var textInputView: ChatInputTextPanel = {
        let view = ChatInputTextPanel(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
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

    fileprivate lazy var textInputViewBottom: NSLayoutConstraint = {
        self.textInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    }()

    fileprivate lazy var textInputViewHeight: NSLayoutConstraint = {
        self.textInputView.heightAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight)
    }()

    fileprivate lazy var controlsViewHeightConstraint: NSLayoutConstraint = {
        self.controlsView.heightAnchor.constraint(equalToConstant: 0)
    }()

    fileprivate lazy var subcontrolsViewHeightConstraint: NSLayoutConstraint = {
        self.subcontrolsView.heightAnchor.constraint(equalToConstant: 0)
    }()

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

    // MARK: - Init

    init(thread: TSThread) {
        self.thread = thread

        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
        title = thread.cachedContactIdentifier

        registerNotifications()
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    fileprivate func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
    }

    // MARK: View life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()

        viewModel.fetchAndUpdateBalance(completion: { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                Navigator.presentModally(alertController)
            } else {
                self.set(balance: balance)
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        isVisible = true

        viewModel.reloadDraft(completion: { placeholder in
            self.textInputView.text = placeholder
        })

        tabBarController?.tabBar.isHidden = true
        
        if let url = viewModel.contactAvatarUrl {
            avatarImageView.setImage(from: url)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
        title = viewModel.thread.cachedContactIdentifier
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        isVisible = false
        heightOfKeyboard = 0

        viewModel.saveDraftIfNeeded(inputViewText: textInputView.text)

        viewModel.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
    }

    fileprivate func addSubviewsAndConstraints() {
        view.addSubview(textInputView)

        NSLayoutConstraint.activate([
                self.textInputView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                self.textInputView.rightAnchor.constraint(equalTo: self.view.rightAnchor),

                self.textInputViewBottom,
                self.textInputViewHeight,
        ])

        view.addSubview(controlsView)

        controlsViewHeightConstraint.isActive = true
        controlsView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        controlsView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        controlsView.bottomAnchor.constraint(equalTo: textInputView.topAnchor).isActive = true
        controlsViewDelegateDatasource.controlsCollectionView = controlsView

        hideSubcontrolsMenu()

        view.backgroundColor = Theme.viewBackgroundColor

        setupActivityIndicator()

        textInputView.delegate = self

        view.addSubview(tableView)

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        tableView.left(to: view)
        tableView.right(to: view)
        tableView.bottomToTop(of: controlsView)

        view.addSubview(ethereumPromptView)

        ethereumPromptView.heightAnchor.constraint(equalToConstant: ChatsFloatingHeaderView.height).isActive = true
        ethereumPromptView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        ethereumPromptView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        ethereumPromptView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        self.setupActiveNetworkView(hidden: true)

        view.addSubview(subcontrolsView)

        subcontrolsViewHeightConstraint.isActive = true
        subcontrolsView.width(ChatController.subcontrolsViewWidth)
        subcontrolsView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        subcontrolsView.bottomAnchor.constraint(equalTo: controlsView.topAnchor, constant: ChatController.buttonMargin).isActive = true
        subcontrolsViewDelegateDatasource.subcontrolsCollectionView = subcontrolsView

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarImageView)
    }

    func sendPayment(with parameters: [String: Any]) {
        showActivityIndicator()
        viewModel.interactor.sendPayment(with: parameters)
    }

    func keyboardWillShow() {
        if textInputView.inputField.isFirstResponder() == true {
            scrollToBottom(animated: false)
        }
    }

    func keyboardDidHide() {
        becomeFirstResponder()
    }

    fileprivate func updateConstraints() {
        textInputViewBottom.constant = heightOfKeyboard < -textInputHeight ? heightOfKeyboard + textInputHeight + buttonsHeight : 0

        textInputViewHeight.constant = textInputHeight

        controlsViewHeightConstraint.constant = buttonsHeight
        keyboardAwareInputView.height = buttonsHeight + textInputHeight
        keyboardAwareInputView.invalidateIntrinsicContentSize()

        view.layoutIfNeeded()
    }

    @objc
    fileprivate func showContactProfile(_ sender: UITapGestureRecognizer) {
        if let contact = self.viewModel.contact as TokenUser?, sender.state == .ended {
            let contactController = ContactController(contact: contact)
            navigationController?.pushViewController(contactController, animated: true)
        }
    }

    @objc
    fileprivate func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        set(balance: balance)
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
            }) { _ in
            }

            var height: CGFloat = 0

            let controlCells = self.controlsView.visibleCells.flatMap { cell in cell as? ControlCell }

            for controlCell in controlCells {
                height = max(height, controlCell.frame.maxY)
            }

            self.controlsViewHeightConstraint.constant = 0
            UIView.animate(withDuration: 0, delay: 0, animations: {
                self.controlsView.layoutIfNeeded()
            }, completion: { completed in

                if completed {
                    self.controlsView.isHidden = false

                    self.buttonsHeight = height > 0 ? height + (2 * ChatController.buttonMargin) : 0

                    guard height > 0 else { return }
                    self.controlsViewHeightConstraint.constant = height

                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                        self.controlsView.layoutIfNeeded()
                    }) { _ in
                        self.scrollToBottom(animated: true)
                    }

                    self.controlsView.deselectButtons()
                }
            })
        }
    }

    fileprivate func scrollToBottom(animated: Bool = true) {
        let numberOfItems = tableView.numberOfRows(inSection: 0)
        guard numberOfItems > 0 else { return }

        let lastIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }

    fileprivate func adjustToPaymentState(_ state: TSInteraction.PaymentState, at indexPath: IndexPath) {
        guard let message = self.viewModel.messageModels[indexPath.row] as MessageModel?, message.type == .paymentRequest || message.type == .payment, let signalMessage = message.signalMessage as TSMessage? else { return }

        signalMessage.paymentState = state
        signalMessage.save()
        
        (tableView.cellForRow(at: indexPath) as? MessagesPaymentCell)?.setPaymentState(signalMessage.paymentState, for: message.type)
        
        tableView.beginUpdates()
        tableView.endUpdates()
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

            imagesCache.setObject(image, forKey: message.identifier as NSString)
        }

        return image
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

    fileprivate func set(balance: NSDecimalNumber) {
        ethereumPromptView.balance = balance
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

            navigationController?.pushViewController(sofaWebController, animated: true)
        } else if button.value != nil {
            buttons = []
            let command = SofaCommand(button: button)
            controlsViewDelegateDatasource.controlsCollectionView?.isUserInteractionEnabled = false
            viewModel.interactor.sendMessage(sofaWrapper: command)
        }
    }

    // MARK: - Camera and picker
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

    fileprivate func checkMicrophoneAccess() {
        if AVAudioSession.sharedInstance().recordPermission().contains(.undetermined) {

            AVAudioSession.sharedInstance().requestRecordPermission { _ in
            }
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

extension ChatController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if viewModel.messageModels[indexPath.row].type == .image {
            
            let controller = ImagesViewController(messages: viewModel.messageModels, initialIndexPath: indexPath)
            controller.transitioningDelegate = self
            controller.dismissDelegate = self
            controller.title = title
            Navigator.presentModally(controller)
        }
    }
}

extension ChatController: UITableViewDataSource {
    
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let messages = self.viewModel.messageModels as [MessageModel]? else { return 0 }

        return messages.count
    }

    public func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = viewModel.messageModels[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: message.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? MessagesBasicCell {
            
            if let url = viewModel.contactAvatarUrl, !message.isOutgoing {
                cell.avatarImageView.setImage(from: url)
            }
            
            cell.isOutGoing = message.isOutgoing
            cell.cornerType = cornerType(for: indexPath)
        }
        
        if let cell = cell as? MessagesImageCell, message.type == .image {
            cell.messageImage = message.image
        } else if let cell = cell as? MessagesPaymentCell, (message.type == .payment) || (message.type == .paymentRequest), let signalMessage = message.signalMessage {
            cell.titleLabel.text = message.title
            cell.subtitleLabel.text = message.subtitle
            cell.messageLabel.text = message.text
            cell.setPaymentState(signalMessage.paymentState, for: message.type)
            cell.selectionDelegate = self

            let isPaymentOpen = (message.signalMessage?.paymentState ?? .none) == .none
            let isMessageActionable = message.isActionable ?? false

            let isOpenPaymentRequest = isMessageActionable && isPaymentOpen
            if isOpenPaymentRequest {
                showActiveNetworkViewIfNeeded()
            }

        } else if let cell = cell as? MessagesTextCell, message.type == .simple {
            cell.messageText = message.text
        }
        
        return cell
    }
    
    private func cornerType(for indexPath: IndexPath) -> MessageCornerType {
        guard let currentMessage = viewModel.messageModels.element(at: indexPath.row) else { return .top }
        guard let previousMessage = viewModel.messageModels.element(at: indexPath.row - 1) else { return .top }
        guard let nextMessage = viewModel.messageModels.element(at: indexPath.row + 1) else {
            return previousMessage.isOutgoing == currentMessage.isOutgoing ? .bottom : .top
        }
        
        if currentMessage.isOutgoing == previousMessage.isOutgoing, currentMessage.isOutgoing == nextMessage.isOutgoing {
            return .middle
        } else if currentMessage.isOutgoing == previousMessage.isOutgoing, currentMessage.isOutgoing != nextMessage.isOutgoing {
            return .bottom
        }
        
        return .top
    }
}

extension MessageModel {
    
    var reuseIdentifier: String {
        switch type {
        case .simple:
            return MessagesTextCell.reuseIdentifier
        case .image:
            return MessagesImageCell.reuseIdentifier
        case .paymentRequest, .payment:
            return MessagesPaymentCell.reuseIdentifier
        case .status:
            return MessagesStatusCell.reuseIdentifier
        }
    }
}


extension ChatController: MessagesPaymentCellDelegate {
    
    func approvePayment(for cell: MessagesPaymentCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) as IndexPath? else { return }
        guard let message = self.viewModel.messageModels.element(at: indexPath.row) as MessageModel? else { return }
        
        adjustToPaymentState(.pendingConfirmation, at: indexPath)
        
        guard let paymentRequest = message.sofaWrapper as? SofaPaymentRequest else { return }
        
        showActivityIndicator()
        
        viewModel.interactor.sendPayment(in: paymentRequest.value, completion: { (success: Bool) in
            let state: TSInteraction.PaymentState = success ? .approved : .failed
            self.adjustToPaymentState(state, at: indexPath)
            DispatchQueue.main.asyncAfter(seconds: 2.0) {
                self.hideActiveNetworkViewIfNeeded()
            }
        })
    }
    
    func declinePayment(for cell: MessagesPaymentCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) as IndexPath? else { return }
        
        adjustToPaymentState(.rejected, at: indexPath)

        DispatchQueue.main.asyncAfter(seconds: 2.0) {
            self.hideActiveNetworkViewIfNeeded()
        }
    }
}

extension ChatController: ImagesViewControllerDismissDelegate {

    func imagesAreDismissed(from indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
}

extension ChatController: ChatViewModelOutput {
    func didReload() {
        for message in viewModel.messages {
            if let paymentRequest = message.sofaWrapper as? SofaPaymentRequest {
                message.fiatValueString = EthereumConverter.fiatValueStringWithCode(forWei: paymentRequest.value, exchangeRate: EthereumAPIClient.shared.exchangeRate)
                message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: paymentRequest.value)
            } else if let payment = message.sofaWrapper as? SofaPayment {
                message.fiatValueString = EthereumConverter.fiatValueStringWithCode(forWei: payment.value, exchangeRate: EthereumAPIClient.shared.exchangeRate)
                message.ethereumValueString = EthereumConverter.ethereumValueString(forWei: payment.value)
            }
        }

        sendGreetingTriggerIfNeeded()

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
            viewModel.interactor.sendMessage(sofaWrapper: SofaMessage(body: ""))
        }
    }
}

extension ChatController: ChatInteractorOutput {

    func didHandleSofaMessage(with buttons: [SofaMessage.Button]) {
        self.buttons = buttons
    }

    func didCatchError(_ error: Error) {
        hideActivityIndicator()

        let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: error.localizedDescription)
        Navigator.presentModally(alert)
    }

    func didFinishRequest() {
        DispatchQueue.main.async {
            self.hideActivityIndicator()
        }
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

        viewModel.interactor.sendMessage(sofaWrapper: wrapper) 
    }

    func inputTextPanelRequestSendAttachment(_: ChatInputTextPanel) {
        view.layoutIfNeeded()

        view.endEditing(true)

        menuSheetController = MenuSheetController()
        menuSheetController?.dismissesByOutsideTap = true
        menuSheetController?.hasSwipeGesture = true
        menuSheetController?.maxHeight = 445 - MenuSheetButtonItemViewHeight
        var itemViews = [UIView]()

        checkMicrophoneAccess()

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

        let galleryItem = MenuSheetButtonItemView(title: "Photo or Video", type: MenuSheetButtonTypeDefault, action: { [unowned self] in

            self.menuSheetController?.dismiss(animated: true)
            self.displayMediaPicker(forFile: false, fromFileMenu: false)
        })!

        itemViews.append(galleryItem)

        carouselItem.underlyingViews = [galleryItem]

        let cancelItem = MenuSheetButtonItemView(title: "Cancel", type: MenuSheetButtonTypeCancel, action: {
            self.menuSheetController?.dismiss(animated: true)
        })!

        itemViews.append(cancelItem)
        menuSheetController?.setItemViews(itemViews)
        carouselItem.remainingHeight = MenuSheetButtonItemViewHeight * CGFloat(itemViews.count - 1)

        menuSheetController?.present(in: self, sourceView: view, animated: true)
    }

    func inputTextPanelDidChangeHeight(_ height: CGFloat) {
        textInputHeight = height
    }
}

extension ChatController: ImagePickerDelegate {
    func cancelButtonDidPress(_: ImagePickerController) {
        dismiss(animated: true)
    }

    func doneButtonDidPress(_: ImagePickerController, images: [UIImage]) {
        dismiss(animated: true) {
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
        view.layoutIfNeeded()
        controlsViewHeightConstraint.constant = 0.0

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

        showActivityIndicator()
        viewModel.interactor.sendPayment(in: valueInWei)
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

        viewModel.interactor.sendMessage(sofaWrapper: paymentRequest)
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
        heightOfKeyboard = keyboardOriginYDistance
    }

    override var inputAccessoryView: UIView? {
        keyboardAwareInputView.isUserInteractionEnabled = false
        return keyboardAwareInputView
    }
}

extension ChatController: ControlViewActionDelegate {
    func controlsCollectionViewDidSelectControl(_ button: SofaMessage.Button) {
        switch button.type {
        case .button:
            didTapControlButton(button)
        case .group:
            updateSubcontrols(with: button)
        }
    }

    func updateSubcontrols(with button: SofaMessage.Button?) {
        switch viewModel.displayState(for: button) {
        case .show:
            showSubcontrolsMenu(button: button!)
        case .hide:
            hideSubcontrolsMenu()
        case .hideAndShow:
            hideSubcontrolsMenu {
                self.showSubcontrolsMenu(button: button!)
            }
        case .doNothing:
            break
        }
    }

    func hideSubcontrolsMenu(completion: (() -> Void)? = nil) {
        subcontrolsViewDelegateDatasource.items = []
        viewModel.currentButton = nil

        subcontrolsViewHeightConstraint.constant = 0
        subcontrolsView.backgroundColor = .clear
        subcontrolsView.isHidden = true

        controlsView.deselectButtons()

        view.layoutIfNeeded()

        completion?()
    }

    func showSubcontrolsMenu(button: SofaMessage.Button, completion: (() -> Void)? = nil) {
        controlsView.deselectButtons()
        subcontrolsViewHeightConstraint.constant = view.frame.height
        subcontrolsView.isHidden = true

        let controlCell = SubcontrolCell(frame: .zero)
        var maxWidth: CGFloat = 0.0

        button.subcontrols.forEach { button in
            controlCell.button.setTitle(button.label, for: .normal)
            let bounds = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 38)
            maxWidth = max(maxWidth, controlCell.button.titleLabel!.textRect(forBounds: bounds, limitedToNumberOfLines: 1).width + controlCell.buttonInsets.left + controlCell.buttonInsets.right)
        }

        subcontrolsViewDelegateDatasource.items = button.subcontrols

        viewModel.currentButton = button

        subcontrolsView.reloadData()

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

extension ChatController: ActiveNetworkDisplaying {

    var activeNetworkView: ActiveNetworkView {
        return networkView
    }

    var activeNetworkViewConstraints: [NSLayoutConstraint] {
         return [activeNetworkView.topAnchor.constraint(equalTo: ethereumPromptView.bottomAnchor, constant: -1),
                 activeNetworkView.leftAnchor.constraint(equalTo: view.leftAnchor),
                 activeNetworkView.rightAnchor.constraint(equalTo: view.rightAnchor)]
    }

    func requestLayoutUpdate() {
        UIView.animate(withDuration: 0.2) {
            self.tableView.contentInset = UIEdgeInsets(top: ChatsFloatingHeaderView.height + 64.0 + (self.activeNetworkView.heightConstraint?.constant ?? 0), left: 0, bottom: 0, right: 0)
            self.view.layoutIfNeeded()
        }
    }
}
