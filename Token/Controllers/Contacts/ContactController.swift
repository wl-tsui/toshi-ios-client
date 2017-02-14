import UIKit
import SweetUIKit
import CoreImage

public class ContactController: ProfileController {

    public var contact: TokenContact

    let yap: Yap = Yap.sharedInstance

    public init(contact: TokenContact, idAPIClient: IDAPIClient) {
        self.contact = contact
        super.init(idAPIClient: idAPIClient)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.updateButton()
    }

    func updateButton() {
        let isContactAdded = self.yap.containsObject(for: contact.address, in: TokenContact.collectionKey)
        let fontColor = isContactAdded ? Theme.greyTextColor : Theme.darkTextColor
        let title = isContactAdded ? "✓ Added" : "Add contact"

        self.editProfileButton.setAttributedTitle(NSAttributedString(string: title, attributes: [NSFontAttributeName: Theme.semibold(size: 13), NSForegroundColorAttributeName: fontColor]), for: .normal)
        self.editProfileButton.removeTarget(nil, action: nil, for: .allEvents)
        self.editProfileButton.addTarget(self, action: #selector(didTapAddContactButton), for: .touchUpInside)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.nameLabel.text = self.contact.username
        self.aboutContentLabel.text = self.contact.about
        self.locationContentLabel.text = self.contact.location
        self.avatar.image = self.contact.avatar ?? #imageLiteral(resourceName: "colin")
    }

    func didTapAddContactButton() {
        if !self.yap.containsObject(for: contact.address, in: TokenContact.collectionKey) {
            self.yap.insert(object: contact.JSONData, for: contact.address, in: TokenContact.collectionKey)

            TSStorageManager.shared().dbConnection.readWrite { transaction in
                var recipient = SignalRecipient(textSecureIdentifier: self.contact.address, with: transaction)

                if recipient == nil {
                    recipient = SignalRecipient(textSecureIdentifier: self.contact.address, relay: nil, supportsVoice: false)
                }

                recipient?.save(with: transaction)

                TSContactThread.getOrCreateThread(withContactId: self.contact.address, transaction: transaction)
            }

            self.updateButton()
        }
    }
}
