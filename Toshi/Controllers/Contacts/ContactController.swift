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
import CoreImage

public class ContactController: UIViewController {

    fileprivate lazy var activityView: UIActivityIndicatorView = {
        self.defaultActivityIndicator()
    }()

    public var contact: TokenUser

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    fileprivate var messageSender: MessageSender? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }

        return appDelegate.messageSender
    }

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.font = Theme.regular(size: 24)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var aboutContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 17)
        view.numberOfLines = 0

        return view
    }()

    lazy var locationContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.lightGreyTextColor
        view.numberOfLines = 0

        return view
    }()

    lazy var actionsSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    lazy var actionView: ContactActionView = {
        let view = ContactActionView()

        view.messageButton.addTarget(self, action: #selector(self.didTapMessageContactButton), for: .touchUpInside)
        view.addFavoriteButton.addTarget(self, action: #selector(self.didTapAddContactButton), for: .touchUpInside)
        view.payButton.addTarget(self, action: #selector(self.didTapPayButton), for: .touchUpInside)

        return view
    }()

    lazy var contentBackgroundView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.viewBackgroundColor

        return view
    }()

    lazy var topSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    lazy var reputationSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    lazy var reputationTitle: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 13)
        view.textColor = Theme.sectionTitleColor
        view.text = "REPUTATION"

        return view
    }()

    lazy var bottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    lazy var reputationView: ReputationView = {
        let view = ReputationView(withAutoLayout: true)

        return view
    }()

    lazy var rateThisUserButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setTitle("Rate this user", for: .normal)
        view.setTitleColor(Theme.tintColor, for: .normal)
        view.setTitleColor(Theme.greyTextColor, for: .highlighted)
        view.titleLabel?.font = Theme.regular(size: 17)

        view.addTarget(self, action: #selector(self.didTapRateUser), for: .touchUpInside)

        return view
    }()

    lazy var reputationBackgroundView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.viewBackgroundColor

        return view
    }()

    public init(contact: TokenUser) {
        self.contact = contact

        super.init(nibName: nil, bundle: nil)

        self.edgesForExtendedLayout = .bottom
        self.title = "Contact"
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    open override func loadView() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true

        self.view = scrollView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.setupActivityIndicator()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "more"), style: .plain, target: self, action: #selector(self.displayActions))
        self.view.backgroundColor = Theme.settingsBackgroundColor

        self.addSubviewsAndConstraints()

        self.reputationView.setScore(.zero)
        self.updateReputation()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.contact.name.isEmpty {
            self.usernameLabel.text = nil
            self.nameLabel.text = self.contact.displayUsername
        } else {
            self.nameLabel.text = self.contact.name
            self.usernameLabel.text = self.contact.displayUsername
        }

        self.aboutContentLabel.text = self.contact.about
        self.locationContentLabel.text = self.contact.location

        if let path = self.contact.avatarPath as String? {
            AvatarManager.shared.avatar(for: path) { image in
                if image != nil {
                    self.avatarImageView.image = image
                }
            }
        }

        self.updateButton()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let scrollView = self.view as? UIScrollView else { return }
        scrollView.contentSize.height = self.bottomSeparatorView.frame.maxY
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.reputationBackgroundView)
        self.view.addSubview(self.contentBackgroundView)

        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.usernameLabel)
        self.view.addSubview(self.aboutContentLabel)
        self.view.addSubview(self.locationContentLabel)

        self.view.addSubview(self.actionsSeparatorView)
        self.view.addSubview(self.actionView)

        self.view.addSubview(self.topSeparatorView)

        self.view.addSubview(self.reputationTitle)

        self.view.addSubview(self.reputationSeparatorView)

        self.view.addSubview(self.reputationView)
        self.view.addSubview(self.rateThisUserButton)
        self.view.addSubview(self.bottomSeparatorView)

        let height: CGFloat = 26.0
        let marginHorizontal: CGFloat = 16.0
        let marginVertical: CGFloat = 14.0
        let itemSpacing: CGFloat = 8.0
        let avatarSize: CGFloat = 60.0

        self.avatarImageView.set(height: avatarSize)
        self.avatarImageView.set(width: avatarSize)
        self.avatarImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 28).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true

        self.nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.topAnchor).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: marginHorizontal).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: itemSpacing).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: marginHorizontal).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.aboutContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.aboutContentLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: marginVertical).isActive = true
        self.aboutContentLabel.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.aboutContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.locationContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.locationContentLabel.topAnchor.constraint(equalTo: self.aboutContentLabel.bottomAnchor, constant: itemSpacing).isActive = true
        self.locationContentLabel.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.locationContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.locationContentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -marginVertical).isActive = true

        self.actionsSeparatorView.topAnchor.constraint(equalTo: self.locationContentLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.actionsSeparatorView.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.actionsSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.actionsSeparatorView.bottomAnchor.constraint(equalTo: self.actionView.topAnchor, constant: -marginVertical).isActive = true

        self.actionView.set(height: 54)
        self.actionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.actionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.contentBackgroundView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.contentBackgroundView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.contentBackgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.contentBackgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.contentBackgroundView.bottomAnchor.constraint(equalTo: self.topSeparatorView.topAnchor).isActive = true

        // We set the view and separator width cosntraints to be the same, to force the scrollview content size to conform to the window
        // otherwise no view is requiring a width of the window, and the scrollview contentSize will shrink to the smallest
        // possible width that satisfy all other constraints.
        self.topSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.topSeparatorView.topAnchor.constraint(equalTo: self.actionView.bottomAnchor, constant: marginVertical).isActive = true
        self.topSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.topSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationTitle.set(height: 18)
        self.reputationTitle.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.reputationTitle.bottomAnchor.constraint(equalTo: self.reputationSeparatorView.topAnchor, constant: -8.0).isActive = true

        self.reputationSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.reputationSeparatorView.topAnchor.constraint(equalTo: self.topSeparatorView.bottomAnchor, constant: 66.0).isActive = true
        self.reputationSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.reputationSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationView.topAnchor.constraint(equalTo: self.reputationSeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.reputationView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.reputationView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.rateThisUserButton.set(height: 22)
        self.rateThisUserButton.topAnchor.constraint(equalTo: self.reputationView.bottomAnchor, constant: 30).isActive = true
        self.rateThisUserButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.reputationBackgroundView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.reputationBackgroundView.topAnchor.constraint(equalTo: self.reputationSeparatorView.bottomAnchor).isActive = true
        self.reputationBackgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.reputationBackgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.reputationBackgroundView.bottomAnchor.constraint(equalTo: self.bottomSeparatorView.topAnchor).isActive = true

        self.bottomSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.bottomSeparatorView.topAnchor.constraint(equalTo: self.rateThisUserButton.bottomAnchor, constant: 20).isActive = true
        self.bottomSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.bottomSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }

    func updateButton() {
        let isContactAdded = Yap.sharedInstance.containsObject(for: self.contact.address, in: TokenUser.favoritesCollectionKey)
        let fontColor = isContactAdded ? Theme.tintColor : Theme.lightGreyTextColor
        let title = isContactAdded ? "Favorited" : "Favorite"

        self.actionView.addFavoriteButton.titleLabel.text = title
        self.actionView.addFavoriteButton.tintColor = fontColor
    }

    @objc private func didTapMessageContactButton() {
        // create thread if needed
        ChatsController.getOrCreateThread(for: self.contact.address)

        DispatchQueue.main.async {
            (self.tabBarController as? TabBarController)?.displayMessage(forAddress: self.contact.address)

            if let navController = self.navigationController as? BrowseNavigationController {
                _ = navController.popToRootViewController(animated: false)
            }
        }
    }

    @objc private func didTapAddContactButton() {
        if Yap.sharedInstance.containsObject(for: self.contact.address, in: TokenUser.favoritesCollectionKey) {
            Yap.sharedInstance.removeObject(for: self.contact.address, in: TokenUser.favoritesCollectionKey)

            self.updateButton()
        } else {
            Yap.sharedInstance.insert(object: self.contact.JSONData, for: self.contact.address, in: TokenUser.favoritesCollectionKey)
            SoundPlayer.playSound(type: .addedContact)
            self.updateButton()
        }
    }

    @objc private func didTapPayButton() {
        let paymentSendController = PaymentSendController()
        paymentSendController.delegate = self

        Navigator.presentModally(paymentSendController)
    }

    func didTapRateUser() {
        self.presentUserRatingPrompt(contact: self.contact)
    }

    private func presentUserRatingPrompt(contact: TokenUser) {
        let rateUserController = RateUserController(user: contact)
        rateUserController.delegate = self

        Navigator.presentModally(rateUserController)
    }

    @objc private func displayActions() {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let blockingManager = OWSBlockingManager.shared()
        let address = self.contact.address

        if self.contact.isBlocked {
            actions.addAction(UIAlertAction(title: "Unblock", style: .destructive, handler: { _ in
                blockingManager.removeBlockedPhoneNumber(address)
            }))
        } else {
            actions.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { _ in
                blockingManager.addBlockedPhoneNumber(address)
            }))
        }

        actions.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { _ in
            self.idAPIClient.reportUser(address: address) { success, errorMessage in
                print(success)
                print(errorMessage)
            }
        }))

        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        Navigator.presentModally(actions)
    }

    fileprivate func updateReputation() {
        RatingsClient.shared.scores(for: self.contact.address) { ratingScore in
            self.reputationView.setScore(ratingScore)
        }
    }
}

extension ContactController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}

extension ContactController: RateUserControllerDelegate {
    func didRate(_ user: TokenUser, rating: Int, review: String) {
        self.dismiss(animated: true) {
            RatingsClient.shared.submit(userId: user.address, rating: rating, review: review) {
                self.updateReputation()
            }
        }
    }
}

extension ContactController: PaymentSendControllerDelegate {
    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let value = valueInWei else {
            return
        }

        let etherAPIClient = EthereumAPIClient.shared

        let parameters: [String: Any] = [
            "from": Cereal.shared.paymentAddress,
            "to": self.contact.paymentAddress,
            "value": value.toHexString,
        ]

        self.showActivityIndicator()

        etherAPIClient.createUnsignedTransaction(parameters: parameters) { transaction, error in

            guard let transaction = transaction as String? else {
                self.hideActivityIndicator()
                let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: error?.localizedDescription)
                Navigator.presentModally(alert)

                return
            }

            let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

            etherAPIClient.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { json, error in

                self.hideActivityIndicator()

                if error != nil {

                    var message = "Something went wrong"
                    if let json = json?.dictionary as [String: Any]?, let jsonMessage = json["message"] as? String {
                        message = jsonMessage
                    }

                    let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: message)
                    Navigator.presentModally(alert)
                } else if let json = json?.dictionary {
                    guard let txHash = json["tx_hash"] as? String else { fatalError("Error recovering transaction hash.") }
                    let payment = SofaPayment(txHash: txHash, valueHex: value.toHexString)

                    // send message to thread
                    let thread = ChatsController.getOrCreateThread(for: self.contact.address)
                    let timestamp = NSDate.ows_millisecondsSince1970(for: Date())
                    let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: thread, messageBody: payment.content)

                    self.messageSender?.send(outgoingMessage, success: {
                        print("message sent")
                    }, failure: { error in
                        print(error)
                    })
                }
            }
        }
    }
}
