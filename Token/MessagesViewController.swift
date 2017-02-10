import UIKit
import SweetUIKit
import JSQMessages

class MessagesViewController: JSQMessagesViewController {

    let etherAPIClient = EthereumAPIClient.shared

    var messages = [TextMessage]()

    var interactions = [TextMessage]() {
        didSet {
            self.messages = self.interactions.filter { message -> Bool in
                return message.isDisplayable
            }
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

    fileprivate lazy var contactAvatar: JSQMessagesAvatarImage = {
        let img = [#imageLiteral(resourceName: "igor"), #imageLiteral(resourceName: "colin")].any!
        return JSQMessagesAvatarImageFactory(diameter: 44).avatarImage(with: img)
    }()

    var thread: TSThread

    var chatAPIClient: ChatAPIClient

    var ethereumAPIClient: EthereumAPIClient

    var messageSender: MessageSender

    var contactsManager: ContactsManager

    var contactsUpdater: ContactsUpdater

    var storageManager: TSStorageManager

    let cereal = Cereal()

    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()

    lazy var ethereumPromptView: MessagesFloatingView = {
        let view = MessagesFloatingView(withAutoLayout: true)
        view.delegate = self

        return view
    }()

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

    override func senderId() -> String {
        return self.cereal.address
    }

    override func senderDisplayName() -> String {
        return thread.name()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        self.collectionView?.backgroundColor = Theme.messageViewBackgroundColor
        self.collectionView?.actionsDelegate = self

        self.inputToolbar.contentView?.leftBarButtonItem = nil

        self.view.addSubview(self.ethereumPromptView)
        self.ethereumPromptView.heightAnchor.constraint(equalToConstant: MessagesFloatingView.height).isActive = true
        self.ethereumPromptView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.ethereumPromptView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.ethereumPromptView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.collectionView?.keyboardDismissMode = .interactive

        self.collectionView?.backgroundColor = Theme.messageViewBackgroundColor

        self.ethereumAPIClient.getBalance(address: self.cereal.address) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.ethereumPromptView.balance = balance
            }
        }

        let statusbarHeight: CGFloat = 20.0
        self.additionalContentInset.top += MessagesFloatingView.height + statusbarHeight

        self.loadMessages()
    }

    func loadMessages() {
        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)

            for i in 0 ..< self.mappings.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(row: Int(i), section: 0)
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
                guard let interaction = dbExtension.object(at: indexPath, with: self.mappings) as? TSInteraction else { fatalError() }

                DispatchQueue.main.async {
                    self.handleInteraction(interaction)
                }
            }

            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.scrollToBottom(animated: true)
            }
        }
    }

    func showFingerprint(with identityKey: Data, signalId: String) {
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

        let showSafteyNumberAction = UIAlertAction(title: NSLocalizedString("Compare fingerprints.", comment: "Action sheet item"), style: .default, handler: { (_ action: UIAlertAction) -> Void in

            self.showFingerprint(with: errorMessage.newIdentityKey(), signalId: errorMessage.theirSignalId())
        })
        actionSheetController.addAction(showSafteyNumberAction)

        let acceptSafetyNumberAction = UIAlertAction(title: NSLocalizedString("Accept the new contact identity.", comment: "Action sheet item"), style: .default, handler: { (_ action: UIAlertAction) -> Void in

            errorMessage.acceptNewIdentityKey()
            if (errorMessage is TSInvalidIdentityKeySendingErrorMessage) {
                self.messageSender.resendMessage(fromKeyError: (errorMessage as! TSInvalidIdentityKeySendingErrorMessage), success: { () -> Void in
                    print("Got it!")
                }, failure: { (_ error: Error) -> Void in
                    print(error)
                })
            }
        })
        actionSheetController.addAction(acceptSafetyNumberAction)

        self.present(actionSheetController, animated: true, completion: nil)
    }

    /// Handle incoming interactions or previous messages when restoring a conversation.
    ///
    /// - Parameters:
    ///   - interaction: the interaction to handle. Incoming/outgoing messages, wrapping SOFA structures.
    ///   - shouldProcessCommands: If true, will process a sofa wrapper. This means replying to requests, displaying payment UI etc.
    ///
    func handleInteraction(_ interaction: TSInteraction, shouldProcessCommands: Bool = false) {
        if let interaction = interaction as? TSInvalidIdentityKeySendingErrorMessage {
            self.handleInvalidKeyError(interaction)

            return
        }

        // We need to agree on how to deal with some specific sofa messages. For instance, if I receive a payment request
        // and I never answer to it, if I leave the conversation and return, it will no longer be there (as it stands now). But
        // odds are that the user will want to eventually address that payment request, so we should store its state alongside it.
        // That way we know which requests were dealt with and can arrange the UI accordingly.
        if let message = interaction as? TSMessage, shouldProcessCommands {
            let type = SofaType(sofa: message.body!)
            switch type {
            case .metadataRequest:
                let metadataResponse = SofaMetadataResponse(metadataRequest: SofaMetadataRequest(content: message.body!))
                self.sendMessage(sofaWrapper: metadataResponse)
            default:
                break
            }
        }

        if let message = interaction as? TSOutgoingMessage {
            let textMessage = TextMessage(senderId: self.senderId(), displayName: self.senderDisplayName(), date: Date(), sofaWrapper: SofaWrapper.wrapper(content: message.body!))

            self.interactions.append(textMessage)
        } else if let message = interaction as? TSIncomingMessage {
            let name = self.contactsManager.displayName(forPhoneIdentifier: message.authorId)
            let textMessage = TextMessage(senderId: message.authorId, displayName: name, date: message.date(), sofaWrapper: SofaWrapper.wrapper(content: message.body!), shouldProcess: shouldProcessCommands)

            self.interactions.append(textMessage)
        }
    }

    func message(at indexPath: IndexPath) -> TextMessage {
        return self.messages[indexPath.row]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func registerNotifications() {
        let notificationController = NotificationCenter.default
        notificationController.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    func yapDatabaseDidChange(notification: NSNotification) {
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
        self.collectionView?.layoutIfNeeded()
        // ENDHACK to work around radar #28167779

        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        viewConnection.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: self.mappings)

        if messageRowChanges.count == 0 {
            return
        }

        var scrollToBottom = false
        self.uiDatabaseConnection.asyncRead { transaction in
            for change in messageRowChanges as! [YapDatabaseViewRowChange] {
                guard change.type == .insert else { continue }
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
                guard let interaction = dbExtension.object(at: change.newIndexPath, with: self.mappings) as? TSInteraction else { fatalError("woot") }

                if change.type == .insert {
                    scrollToBottom = true
                }

                self.handleInteraction(interaction, shouldProcessCommands: true)
            }

            DispatchQueue.main.async {
                self.collectionView?.reloadData()

                if scrollToBottom {
                    self.scrollToBottom(animated: true)
                }
            }
        }
    }

    // MARK: - Message UI interaction

    override func didPressAccessoryButton(_ sender: UIButton) {
        print("!")
    }

    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        button.isEnabled = false

        self.finishSendingMessage(animated: true)

        let sofaMessage = SofaMessage(content: ["body": text])
        self.sendMessage(sofaWrapper: sofaMessage, date: date)
    }

    func sendMessage(sofaWrapper: SofaWrapper, date: Date = Date()) {
        let timestamp = NSDate.ows_millisecondsSince1970(for: date)
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: sofaWrapper.content)

        self.messageSender.send(outgoingMessage, success: {
            print("Message sent.")
        }, failure: { error in
            print(error)
        })
    }
}

/// Collection view setup
extension MessagesViewController {

    fileprivate func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.outgoingMessagesBubbleImage(with: Theme.outgoingMessageBackgroundColor)
    }

    fileprivate func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.incomingMessagesBubbleImage(with: Theme.incomingMessageBackgroundColor)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return self.message(at: indexPath)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        let message = self.message(at: indexPath)

        if message.senderId == self.senderId() {
            return self.outgoingBubbleImageView
        } else {
            return self.incomingBubbleImageView
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = self.message(at: indexPath)

        if message.senderId == self.senderId() {
            return nil
        }

        // Group messages by the same author together. Only display username for the first one.
        if (indexPath.item - 1 > 0) {
            let previousIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)
            let previousMessage = self.message(at: previousIndexPath)
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }

        return NSAttributedString(string: message.senderDisplayName)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        if (indexPath.item % 3 == 0) {
            let message = self.message(at: indexPath)

            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }

        return nil
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.item % 3 == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }

        return 0.0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {
        return 0.0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell else { fatalError() }

        let message = self.message(at: indexPath)

        cell.messageBubbleTopLabel?.attributedText = self.collectionView(self.collectionView!, attributedTextForMessageBubbleTopLabelAt: indexPath)

        if message.senderId == senderId() {
            cell.textView?.textColor = Theme.outgoingMessageTextColor
        } else {
            cell.textView?.textColor = Theme.incomingMessageTextColor
        }

        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = self.message(at: indexPath)

        if message.senderId == self.senderId() {
            return nil
        }

        return self.contactAvatar
    }
}

extension MessagesViewController: MessagesFloatingViewDelegate {

    // TODO: Implement payment request UI.
    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressRequestButton button: UIButton) {
        let request: [String: Any] = ["body": "Thanks for the great time! Can you send your share of the tab?",
            "value": "1000000000",
            "destinationAddress": self.cereal.address]

        let paymentRequest = SofaPaymentRequest(content: request)

        self.sendMessage(sofaWrapper: paymentRequest)
    }

    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressPayButton button: UIButton) {
        print("pay button pressed")
    }
}

extension MessagesViewController: JSQMessagesViewActionButtonsDelegate {

    public func messageView(_ messageView: JSQMessagesCollectionView, didTapApproveAt indexPath: IndexPath) {
        guard let paymentRequest = self.message(at: indexPath).sofaWrapper as? SofaPaymentRequest else { fatalError("Could not retrieve payment request for approval.") }

        guard let value = paymentRequest.value else { return }
        guard let destination = paymentRequest.destinationAddress else { return }

        // TODO: prevent concurrent calls
        self.etherAPIClient.createUnsignedTransaction(to: destination, value: value) { (transaction, error) in
            let signedTransaction = "0x\(self.cereal.sign(message: transaction!))"

            self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction!, transactionSignature: signedTransaction) { (json, error) in
                if error != nil {
                    guard let json = json?.dictionary else { fatalError("!") }

                    let alert = UIAlertController.dismissableAlert(title: json["message"] as! String, message: json["message"] as? String)
                    self.present(alert, animated: true)
                }
            }
        }
    }

    public func messageView(_ messageView: JSQMessagesCollectionView, didTapRejectAt indexPath: IndexPath) {
        let message = self.message(at: indexPath)
        message.isActionable = false
        self.collectionView?.reloadItems(at: [indexPath])
    }
}
