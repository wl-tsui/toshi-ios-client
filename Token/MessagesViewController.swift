import UIKit
import SweetUIKit
import JSQMessages

class TextMessage: JSQMessage {

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

    var thread: TSThread

    var chatAPIClient: ChatAPIClient

    var messageSender: MessageSender

    var contactsManager: ContactsManager

    var contactsUpdater: ContactsUpdater

    var storageManager: TSStorageManager

    let cereal = Cereal()

    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()

    init(thread: TSThread, chatAPIClient: ChatAPIClient) {
        self.chatAPIClient = chatAPIClient
        self.thread = thread

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError("Could not retrieve app delegate") }

        self.messageSender = appDelegate.messageSender
        self.contactsManager = appDelegate.contactsManager
        self.contactsUpdater = appDelegate.contactsUpdater
        self.storageManager = TSStorageManager.shared()

        super.init(nibName: nil, bundle: nil)

        self.title = thread.name()

        self.senderDisplayName = thread.name()
        self.senderId = self.cereal.address
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.collectionViewLayout.incomingAvatarViewSize = .zero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = .zero

        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    func message(at indexPath: IndexPath) -> TextMessage {
        var interaction: TSInteraction? = nil

        self.uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSInteraction else { fatalError() }

            interaction = object
        }

        /**
         @property (nonatomic, readonly) NSMutableArray<NSString *> *attachmentIds;
         @property (nullable, nonatomic) NSString *body;
         @property (nonatomic) TSGroupMetaMessage groupMetaMessage;
         @property (nonatomic) uint32_t expiresInSeconds;
         @property (nonatomic) uint64_t expireStartedAt;
         @property (nonatomic, readonly) uint64_t expiresAt;
         @property (nonatomic, readonly) BOOL isExpiringMessage;
         @property (nonatomic, readonly) BOOL shouldStartExpireTimer;
         */

        let date = NSDate.ows_date(withMillisecondsSince1970: interaction!.timestamp)
        if let interaction = interaction as? TSOutgoingMessage {
            let textMessage = TextMessage(senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: date, text: interaction.body)

            return textMessage!
        } else if let interaction = interaction as? TSIncomingMessage {
            let name = self.contactsManager.displayName(forPhoneIdentifier: interaction.authorId)
            let textMessage = TextMessage(senderId: interaction.authorId, senderDisplayName: name, date: date, text: interaction.body)

            return textMessage!
        } else {
            if let info = interaction as? TSInfoMessage {
                print(info)
            } else {
                print("Neither incoming nor outgoing message!")
            }
        }

        return TextMessage(senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: date, text: "This is not a real message. \(interaction)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - Message UI interaction

    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("!")
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        button.isEnabled = false

        let timestamp = NSDate.ows_millisecondsSince1970(for: date)
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: text)
        self.messageSender.send(outgoingMessage, success: {
            print("message sent!")

            DispatchQueue.main.async {
                self.finishSendingMessage(animated: true)
            }
//            guard let textMessage = TextMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text) else { fatalError("Could not create outgoing text message!") }
//            self.messages.append(textMessage)
        }, failure: { error in
            print(error)
        })
    }

    // MARK: - CollectionView Setup

    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }

    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.message(at: indexPath)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.message(at: indexPath)

        if message.senderId == self.senderId {
            return self.outgoingBubbleImageView
        } else {
            return self.incomingBubbleImageView
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = self.message(at: indexPath)

        if message.senderId == self.senderId {
            return nil
        }

        // Group messages by the same author together. Only display username for the first one.
        if (indexPath.item - 1 > 0) {
            let previousIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)
            let previousMessage = self.message(at: previousIndexPath)
            if previousMessage.senderId == message.senderId {
                return nil;
            }
        }

        return NSAttributedString(string: message.senderDisplayName)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if (indexPath.item % 3 == 0) {
            let message = self.message(at: indexPath)

            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }

        return nil
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if (indexPath.item % 3 == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }

        return 0.0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0.0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell else { fatalError() }

        let message = self.message(at: indexPath)

        cell.messageBubbleTopLabel.attributedText = self.collectionView(self.collectionView, attributedTextForMessageBubbleTopLabelAt: indexPath)

        if message.senderId == senderId {
            cell.textView.textColor = UIColor.white
        } else {
            cell.textView.textColor = UIColor.black
        }

        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
}
