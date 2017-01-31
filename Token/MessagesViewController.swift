import UIKit
import SweetUIKit

class TextMessage: JSQMessage {

    private var sofaWrapper: SofaWrapper!

    override var text: String! {
        get {
            guard let text = super.text else { return "" }

            if self.sofaWrapper == nil {
                self.sofaWrapper = SofaWrapper(sofaContent: text)
            }

            return self.sofaWrapper.body
        }
    }
}

class MessagesViewController: JSQMessagesViewController {

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

    private lazy var contactAvatar: JSQMessagesAvatarImage = {
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

        self.inputToolbar.contentView?.leftBarButtonItem = nil

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }

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
    }

    func message(at indexPath: IndexPath) -> TextMessage {
        var interaction: TSInteraction? = nil

        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSInteraction else { fatalError() }

            interaction = object
        }

        let date = NSDate.ows_date(withMillisecondsSince1970: interaction!.timestamp)
        if let interaction = interaction as? TSOutgoingMessage {
            let textMessage = TextMessage(senderId: self.senderId(), senderDisplayName: self.senderDisplayName(), date: date!, text: interaction.body!)

            return textMessage
        } else if let interaction = interaction as? TSIncomingMessage {
            let name = self.contactsManager.displayName(forPhoneIdentifier: interaction.authorId)
            let textMessage = TextMessage(senderId: interaction.authorId, senderDisplayName: name, date: date!, text: interaction.body!)

            return textMessage
        } else {
            if let info = interaction as? TSInfoMessage {
                print(info)
            } else {
                print("Neither incoming nor outgoing message!")
            }
        }

        let text = (interaction as? TSInfoMessage)?.description ?? ""
        return TextMessage(senderId: self.senderId(), senderDisplayName: self.senderDisplayName(), date: date!, text: NSLocalizedString(text, comment: ""))
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

        var scrollToBottom = false

        if sectionChanges.count == 0 && messageRowChanges.count == 0 {
            return
        }

        self.collectionView?.performBatchUpdates({
            for rowChange in (messageRowChanges as! [YapDatabaseViewRowChange]) {
                switch (rowChange.type) {
                case .delete:
                    self.collectionView?.deleteItems(at: [rowChange.indexPath])
                case .insert:
                    self.collectionView?.insertItems(at: [rowChange.newIndexPath])
                    scrollToBottom = true
                case .move:
                    self.collectionView?.deleteItems(at: [rowChange.indexPath])
                    self.collectionView?.insertItems(at: [rowChange.newIndexPath])
                case .update:
                    self.collectionView?.reloadItems(at: [rowChange.indexPath])
                }
            }

        }) { (success) in
            if !success {
                self.collectionView?.collectionViewLayout.invalidateLayout(with: JSQMessagesCollectionViewFlowLayoutInvalidationContext())
                self.collectionView?.reloadData()
            }

            if scrollToBottom {
                self.scrollToBottom(animated: true)
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

        let timestamp = NSDate.ows_millisecondsSince1970(for: date)

        let sofa = SofaWrapper(messageBody: text)

        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: sofa.content)
        self.messageSender.send(outgoingMessage, success: {
            print("Message sent.")
        }, failure: { error in
            print(error)
        })
    }

    // MARK: - CollectionView Setup

    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.outgoingMessagesBubbleImage(with: Theme.outgoingMessageBackgroundColor)
    }

    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.incomingMessagesBubbleImage(with: Theme.incomingMessageBackgroundColor)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
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

        //        if message.senderId == self.senderId {
        return nil
        //        }
        //
        // Group messages by the same author together. Only display username for the first one.
        //        if (indexPath.item - 1 > 0) {
        //            let previousIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)
        //            let previousMessage = self.message(at: previousIndexPath)
        //            if previousMessage.senderId == message.senderId {
        //                return nil
        //            }
        //        }
        //
        // return NSAttributedString(string: message.senderDisplayName)
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

    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressRequestButton button: UIButton) {
        print("request button")
    }

    func messagesFloatingView(_ messagesFloatingView: MessagesFloatingView, didPressPayButton button: UIButton) {
        print("pay button")
    }
}
