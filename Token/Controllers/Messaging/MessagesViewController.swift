import UIKit
import SweetUIKit
import NoChat

class MessagesViewController: MessagesCollectionViewController {

    let etherAPIClient = EthereumAPIClient.shared

    var textLayoutQueue = DispatchQueue(label: "com.tokenbrowser.token.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))

    var messages = [Message]() {
        didSet {
            let current = Set(self.messages)
            let previous = Set(oldValue)
            let new = current.subtracting(previous).sorted { (message1, message2) -> Bool in
                return message1.date.compare(message2.date) == .orderedAscending
            }

            let displayables = new.filter { (message) -> Bool in
                return message.isDisplayable
            }

            // Only animate if we're adding one message, for bulk-insert we want them instant.
            let isAnimated = displayables.count == 1
            self.addMessages(displayables, scrollToBottom: true, animated: isAnimated)
        }
    }

    var visibleMessages: [Message] {
        return self.messages.filter { (message) -> Bool in
            message.isDisplayable
        }
    }

    lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [self.thread.uniqueId], view: TSMessageDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    lazy var editingDatabaseConnection: YapDatabaseConnection = {
        self.storageManager.newDatabaseConnection()
    }()

    var thread: TSThread

    var chatAPIClient: ChatAPIClient

    var ethereumAPIClient: EthereumAPIClient

    var messageSender: MessageSender

    var contactsManager: ContactsManager

    var contactsUpdater: ContactsUpdater

    var storageManager: TSStorageManager

    let cereal = Cereal()

    lazy var ethereumPromptView: MessagesFloatingView = {
        let view = MessagesFloatingView(withAutoLayout: true)
        view.delegate = self

        return view
    }()

    // MARK: - Class overrides

    override class func cellLayoutClass(forItemType type: String) -> AnyClass? {
        if type == "Text" {
            return MessageCellLayout.self
        } else if type == "Actionable" {
            return ActionableMessageCellLayout.self
        } else {
            return nil
        }
    }

    override class func inputPanelClass() -> AnyClass? {
        return ChatInputTextPanel.self
    }

    // MARK: - Init

    init(thread: TSThread, chatAPIClient: ChatAPIClient, ethereumAPIClient: EthereumAPIClient = .shared) {
        self.chatAPIClient = chatAPIClient
        self.ethereumAPIClient = ethereumAPIClient
        self.thread = thread

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError("Could not retrieve app delegate") }

        self.messageSender = appDelegate.messageSender
        self.contactsManager = appDelegate.contactsManager
        self.contactsUpdater = appDelegate.contactsUpdater
        self.storageManager = TSStorageManager.shared()

        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true

        self.title = thread.name()

        self.registerNotifications()
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: View life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.additionalContentInsets.top = MessagesFloatingView.height
        self.collectionView.backgroundColor = Theme.messageViewBackgroundColor

        self.view.addSubview(self.ethereumPromptView)
        self.ethereumPromptView.heightAnchor.constraint(equalToConstant: MessagesFloatingView.height).isActive = true
        self.ethereumPromptView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.ethereumPromptView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.ethereumPromptView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.collectionView.keyboardDismissMode = .interactive
        self.collectionView.backgroundColor = Theme.messageViewBackgroundColor

        self.updateBalance()
        self.loadMessages()
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        self.inputPanel?.becomeFirstResponder()
        self.inputPanel?.resignFirstResponder()
        self.reloadDraft()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.saveDraft()

        self.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
    }

    func updateBalance(_: Notification? = nil) {
        self.ethereumAPIClient.getBalance(address: self.cereal.paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.set(balance: balance)
            }
        }
    }

    func set(balance: NSDecimalNumber) {
        self.ethereumPromptView.balance = balance
    }

    func saveDraft() {
        guard let inputPanel = self.inputPanel as? ChatInputTextPanel else { return }

        let thread = self.thread
        guard let text = inputPanel.text else { return }

        self.editingDatabaseConnection.asyncReadWrite { transaction in
            thread.setDraft(text, transaction: transaction)
        }
    }

    func reloadDraft() {
        let thread = self.thread
        var placeholder: String?

        self.editingDatabaseConnection.asyncReadWrite({ transaction in
            placeholder = thread.currentDraft(with: transaction)
        }, completionBlock: {
            DispatchQueue.main.async {
                guard let inputPanel = self.inputPanel as? ChatInputTextPanel else { return }
                inputPanel.text = placeholder
            }
        })
    }

    override func registerChatItemCells() {
        self.collectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.reuseIdentifier())
        self.collectionView.register(ActionableMessageCell.self, forCellWithReuseIdentifier: ActionableMessageCell.reuseIdentifier())
    }

    // MARK: Load initial messages

    func loadMessages() {
        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)

            var messages = [Message]()

            for i in 0 ..< self.mappings.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(row: Int(i), section: 0)
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
                guard let interaction = dbExtension.object(at: indexPath, with: self.mappings) as? TSInteraction else { fatalError() }

                DispatchQueue.main.async {
                    var shouldProcess = false
                    if let message = interaction as? TSMessage, SofaType(sofa: message.body ?? "") == .paymentRequest {
                        shouldProcess = true
                    }

                    messages.append(self.handleInteraction(interaction, shouldProcessCommands: shouldProcess))
                }
            }

            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.messages = messages
                    self.collectionView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            }
        }
    }

    // Mark: Handle new messages

    func showFingerprint(with _: Data, signalId _: String) {
        // Postpone this for now
        print("Should display fingerprint comparison UI.")
        //        let builder = OWSFingerprintBuilder(storageManager: self.storageManager, contactsManager: self.contactsManager)
        //        let fingerprint = builder.fingerprint(withTheirSignalId: signalId, theirIdentityKey: identityKey)
        //
        //        let fingerprintController = FingerprintViewController(fingerprint: fingerprint)
        //        self.present(fingerprintController, animated: true)
    }

    func handleInvalidKeyError(_ errorMessage: TSInvalidIdentityKeyErrorMessage) {
        let keyOwner = self.contactsManager.displayName(forPhoneIdentifier: errorMessage.theirSignalId())
        let titleText = "Your safety number with \(keyOwner) has changed. You may wish to verify it."

        let actionSheetController = UIAlertController(title: titleText, message: nil, preferredStyle: .actionSheet)

        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheetController.addAction(dismissAction)

        let showSafteyNumberAction = UIAlertAction(title: NSLocalizedString("Compare fingerprints.", comment: "Action sheet item"), style: .default) { (_: UIAlertAction) -> Void in

            self.showFingerprint(with: errorMessage.newIdentityKey(), signalId: errorMessage.theirSignalId())
        }
        actionSheetController.addAction(showSafteyNumberAction)

        let acceptSafetyNumberAction = UIAlertAction(title: NSLocalizedString("Accept the new contact identity.", comment: "Action sheet item"), style: .default) { (_: UIAlertAction) -> Void in

            errorMessage.acceptNewIdentityKey()
            if errorMessage is TSInvalidIdentityKeySendingErrorMessage {
                self.messageSender.resendMessage(fromKeyError: (errorMessage as! TSInvalidIdentityKeySendingErrorMessage), success: { () -> Void in
                    print("Got it!")
                }, failure: { (_ error: Error) -> Void in
                    print(error)
                })
            }
        }
        actionSheetController.addAction(acceptSafetyNumberAction)

        self.present(actionSheetController, animated: true, completion: nil)
    }

    /// Handle incoming interactions or previous messages when restoring a conversation.
    ///
    /// - Parameters:
    ///   - interaction: the interaction to handle. Incoming/outgoing messages, wrapping SOFA structures.
    ///   - shouldProcessCommands: If true, will process a sofa wrapper. This means replying to requests, displaying payment UI etc.
    ///
    func handleInteraction(_ interaction: TSInteraction, shouldProcessCommands: Bool = false) -> Message {
        if let interaction = interaction as? TSInvalidIdentityKeySendingErrorMessage {
            DispatchQueue.main.async {
                self.handleInvalidKeyError(interaction)
            }

            return Message(sofaWrapper: nil, signalMessage: interaction, date: interaction.date(), isOutgoing: false)
        }

        if let message = interaction as? TSMessage, shouldProcessCommands {
            let type = SofaType(sofa: message.body)
            switch type {
            case .metadataRequest:
                let metadataResponse = SofaMetadataResponse(metadataRequest: SofaMetadataRequest(content: message.body!))
                self.sendMessage(sofaWrapper: metadataResponse)
            default:
                break
            }
        }

        /// TODO: Simplify how we deal with interactions vs text messages.
        /// Since now we know we can expande the TSInteraction stored properties, maybe we can merge some of this together.
        if let interaction = interaction as? TSOutgoingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body!)
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.date(), isOutgoing: true)

            if let payment = SofaWrapper.wrapper(content: interaction.body ?? "") as? SofaPayment {
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: "Payment sent", attributes: [NSForegroundColorAttributeName: Theme.outgoingMessageTextColor, NSFontAttributeName: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value).string, attributes: [NSForegroundColorAttributeName: Theme.outgoingMessageTextColor, NSFontAttributeName: Theme.regular(size: 15)])
            }

            return message
        } else if let interaction = interaction as? TSIncomingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body!)
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.date(), isOutgoing: false, shouldProcess: shouldProcessCommands && interaction.paymentState == .none)

            if let message = sofaWrapper as? SofaMessage {
                self.buttons = message.buttons
            } else if let paymentRequest = sofaWrapper as? SofaPaymentRequest {
                message.messageType = "Actionable"
                message.title = "Payment request"
                message.attributedSubtitle = EthereumConverter.balanceAttributedString(forWei: paymentRequest.value)
            } else if let payment = sofaWrapper as? SofaPayment {
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: "Payment received", attributes: [NSForegroundColorAttributeName: Theme.incomingMessageTextColor, NSFontAttributeName: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value).string, attributes: [NSForegroundColorAttributeName: Theme.incomingMessageTextColor, NSFontAttributeName: Theme.regular(size: 15)])
            }

            return message
        } else {
            return Message(sofaWrapper: nil, signalMessage: interaction as! TSMessage, date: interaction.date(), isOutgoing: false)
        }
    }

    // MARK: Add displayable messages

    private func addMessages(_ messages: [Message], scrollToBottom: Bool, animated: Bool) {
        self.textLayoutQueue.async {
            let indexes = IndexSet(integersIn: 0 ..< messages.count)

            var layouts = [NOCChatItemCellLayout]()

            for message in messages {
                let layout = self.createLayout(with: message)!
                layouts.append(layout)
            }

            DispatchQueue.main.async {
                self.insertLayouts(layouts.reversed(), at: indexes, animated: animated)
                if scrollToBottom {
                    self.scrollToBottom(animated: animated)
                }
            }
        }
    }

    // MARK: - Helper methods

    func visibleMessage(at indexPath: IndexPath) -> Message {
        return self.visibleMessages[indexPath.row]
    }

    func message(at indexPath: IndexPath) -> Message {
        return self.messages[indexPath.row]
    }

    func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateBalance), name: .ethereumPaymentConfirmationNotification, object: nil)
    }

    func reversedIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row = (self.visibleMessages.count - 1) - indexPath.item
        return IndexPath(row: row, section: indexPath.section)
    }

    // MARK: Handle database changes

    func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = self.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // TODO: Since this is used in more than one place, we should look into abstracting this away, into our own
        // table/collection view backing model.
        let viewConnection = self.uiDatabaseConnection.ext(TSMessageDatabaseViewExtensionName) as! YapDatabaseViewConnection
        let hasChangesForCurrentView = viewConnection.hasChanges(for: notifications)
        if !hasChangesForCurrentView {
            self.uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        // HACK to work around radar #28167779
        // "UICollectionView performBatchUpdates can trigger a crash if the collection view is flagged for layout"
        // more: https://github.com/PSPDFKit-labs/radar.apple.com/tree/master/28167779%20-%20CollectionViewBatchingIssue
        // This was our #2 crash, and much exacerbated by the refactoring somewhere between 2.6.2.0-2.6.3.8
        self.collectionView.layoutIfNeeded() // ENDHACK to work around radar #28167779

        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        viewConnection.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: self.mappings)

        if messageRowChanges.count == 0 {
            return
        }

        self.uiDatabaseConnection.asyncRead { transaction in
            for change in messageRowChanges as! [YapDatabaseViewRowChange] {
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }

                switch change.type {
                case .insert:
                    guard let interaction = dbExtension.object(at: change.newIndexPath, with: self.mappings) as? TSInteraction else { fatalError("woot") }

                    DispatchQueue.main.async {
                        let result = self.handleInteraction(interaction, shouldProcessCommands: true)
                        self.messages.append(result)

                        if result.isOutgoing {
                            if result.sofaWrapper?.type == .paymentRequest {
                                SoundPlayer.playSound(type: .requestPayment)
                            } else if result.sofaWrapper?.type == .payment {
                                SoundPlayer.playSound(type: .paymentSend)
                            } else {
                                SoundPlayer.playSound(type: .messageSent)
                            }
                        } else {
                            SoundPlayer.playSound(type: .messageReceived)
                        }

                        if let incoming = interaction as? TSIncomingMessage, !incoming.wasRead {
                            incoming.markAsReadLocally()
                        }
                    }
                case .update:
                    guard let interaction = dbExtension.object(at: change.indexPath, with: self.mappings) as? TSMessage else { continue }

                    let indexPath = change.indexPath
                    let message = self.message(at: indexPath)
                    message.signalMessage = interaction
                    DispatchQueue.main.async {
                        guard self.visibleMessages.count == self.layouts.count else {
                            print("Called before colection view had a chance to insert message.")

                            return
                        }

                        if let visibleIndex = self.visibleMessages.index(of: message), let layout = self.layouts[visibleIndex] as? MessageCellLayout {
                            layout.chatItem = message
                            let visibleIndexPath = self.reversedIndexPath(IndexPath(item: visibleIndex, section: 0))
                            self.collectionView.reloadItems(at: [visibleIndexPath])
                        }
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: Send messages

    func sendMessage(sofaWrapper: SofaWrapper, date: Date = Date()) {
        let timestamp = NSDate.ows_millisecondsSince1970(for: date)
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: sofaWrapper.content)

        self.messageSender.send(outgoingMessage, success: {
            print("message sent")
        }, failure: { error in
            print(error)
        })
    }

    // MARK: - Collection view overrides

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)

        if let cell = cell as? ActionableMessageCell {
            cell.actionsDelegate = self
        }

        return cell
    }

    // MARK: - Control handling

    override func didTapControlButton(_ button: SofaMessage.Button) {
        guard button.value != nil else {
            print("Implement handling actions. action: \(button.action)")

            return
        }
        let command = SofaCommand(button: button)

        self.controlsViewDelegateDatasource.controlsCollectionView?.isUserInteractionEnabled = false
        self.sendMessage(sofaWrapper: command)
    }
}

extension MessagesViewController: ActionableCellDelegate {

    func didTapRejectButton(_ messageCell: ActionableMessageCell) {
        guard let indexPath = self.collectionView.indexPath(for: messageCell) else { return }
        let visibleMessageIndexPath = self.reversedIndexPath(indexPath)

        let message = self.visibleMessage(at: visibleMessageIndexPath)
        message.isActionable = false

        let layout = self.layouts[indexPath.item] as? MessageCellLayout
        layout?.chatItem = message
        layout?.calculate()

        let interaction = message.signalMessage
        interaction.paymentState = .rejected
        interaction.save()
    }

    func didTapApproveButton(_ messageCell: ActionableMessageCell) {
        guard let indexPath = self.collectionView.indexPath(for: messageCell) else { return }
        let visibleMessageIndexPath = self.reversedIndexPath(indexPath)

        let message = self.visibleMessage(at: visibleMessageIndexPath)
        message.isActionable = false

        let layout = self.layouts[indexPath.item] as? MessageCellLayout
        layout?.chatItem = message
        layout?.calculate()

        let interaction = message.signalMessage
        interaction.paymentState = .pendingConfirmation
        interaction.save()

        guard let paymentRequest = message.sofaWrapper as? SofaPaymentRequest else { fatalError("Could not retrieve payment request for approval.") }

        let value = paymentRequest.value
        guard let destination = paymentRequest.destinationAddress else { return }

        // TODO: prevent concurrent calls
        // Also, extract this.
        self.etherAPIClient.createUnsignedTransaction(to: destination, value: value) { transaction, error in
            let signedTransaction = "0x\(self.cereal.signWithWallet(hex: transaction!))"

            self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction!, transactionSignature: signedTransaction) { json, error in
                if error != nil {
                    guard let json = json?.dictionary else { fatalError("!") }

                    let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: json["message"] as? String)
                    self.present(alert, animated: true)
                } else if let json = json?.dictionary {
                    // update payment request message
                    message.isActionable = false

                    let interaction = message.signalMessage
                    interaction.paymentState = .pendingConfirmation
                    interaction.save()

                    // send payment message
                    guard let txHash = json["tx_hash"] as? String else { fatalError("Error recovering transaction hash.") }
                    let payment = SofaPayment(txHash: txHash, valueHex: value.toHexString)

                    self.sendMessage(sofaWrapper: payment)
                }
            }
        }
    }
}

extension MessagesViewController: ChatInputTextPanelDelegate {

    func inputTextPanel(_: ChatInputTextPanel, requestSendText text: String) {
        let wrapper = SofaMessage(content: ["body": text])
        self.sendMessage(sofaWrapper: wrapper)
    }
}

extension MessagesViewController: MessagesFloatingViewDelegate {

    func messagesFloatingView(_: MessagesFloatingView, didPressRequestButton _: UIButton) {
        let paymentRequestController = PaymentRequestController()
        paymentRequestController.delegate = self

        self.present(paymentRequestController, animated: true)
    }

    func messagesFloatingView(_: MessagesFloatingView, didPressPayButton _: UIButton) {
        let paymentSendController = PaymentSendController()
        paymentSendController.delegate = self

        self.present(paymentSendController, animated: true)
    }
}

extension MessagesViewController: PaymentSendControllerDelegate {

    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let value = valueInWei else {
            return
        }

        // TODO: prevent concurrent calls
        // Also, extract this.
        guard let contact = self.contactsManager.tokenContact(forAddress: self.thread.contactIdentifier()) else {
            return
        }

        self.etherAPIClient.createUnsignedTransaction(to: contact.paymentAddress, value: value) { transaction, error in
            let signedTransaction = "0x\(self.cereal.signWithWallet(hex: transaction!))"

            self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction!, transactionSignature: signedTransaction) { json, error in
                if error != nil {
                    guard let json = json?.dictionary else { fatalError("!") }

                    let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: json["message"] as? String)
                    self.present(alert, animated: true)
                } else if let json = json?.dictionary {
                    guard let txHash = json["tx_hash"] as? String else { fatalError("Error recovering transaction hash.") }
                    let payment = SofaPayment(txHash: txHash, valueHex: value.toHexString)
                    self.sendMessage(sofaWrapper: payment)
                }
            }
        }
    }
}

extension MessagesViewController: PaymentRequestControllerDelegate {

    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let valueInWei = valueInWei else {
            return
        }

        let request: [String: Any] = [
            "body": "Payment request: \(EthereumConverter.balanceAttributedString(forWei: valueInWei).string).",
            "value": valueInWei.toHexString,
            "destinationAddress": self.cereal.paymentAddress,
        ]

        let paymentRequest = SofaPaymentRequest(content: request)

        self.sendMessage(sofaWrapper: paymentRequest)
    }
}
