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

public extension NSNotification.Name {
    public static let UserDidSignOut = NSNotification.Name(rawValue: "UserDidSignOut")
}

open class SettingsController: UITableViewController {

    fileprivate var ethereumAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var isAccountSecured: Bool {
        return TokenUser.current?.verified ?? false
    }

    @IBOutlet weak var ratingsView: UIView! {
        didSet {
            self.ratingsView.isHidden = true
        }
    }

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            self.nameLabel.text = TokenUser.current?.name
        }
    }

    @IBOutlet weak var usernameLabel: UILabel! {
        didSet {
            self.usernameLabel.text = TokenUser.current?.displayUsername
        }
    }

    @IBOutlet weak var userAvatarImageVIew: UIImageView! {
        didSet {
            self.updateAvatar()
        }
    }

    @IBOutlet weak var balanceLabel: UILabel! {
        didSet {
            self.set(balance: .zero)
        }
    }

    @IBOutlet weak var versionLabel: UILabel! {
        didSet {
            let info = Bundle.main.infoDictionary!
            let version = info["CFBundleShortVersionString"] as! String

            self.versionLabel.text = "Version \(version)"
        }
    }

    static func instantiateFromNib() -> SettingsController {
        return UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! SettingsController
    }

    private init() {
        fatalError()
    }

    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .currentUserUpdated, object: nil)

        self.tableView.backgroundColor = Theme.settingsBackgroundColor

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)

        self.fetchAndUpdateBalance()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
        self.nameLabel.text = TokenUser.current?.name
        self.usernameLabel.text = TokenUser.current?.displayUsername
        self.updateAvatar()
    }

    @objc private func updateUI() {
        self.nameLabel.text = TokenUser.current?.name
        self.usernameLabel.text = TokenUser.current?.displayUsername
        self.set(balance: .zero)

        self.updateAvatar()
    }

    fileprivate func updateAvatar() {
        if let avatarPath = TokenUser.current?.avatarPath as String? {
            AvatarManager.shared.avatar(for: avatarPath) { image, _ in
                if image != nil {
                    self.userAvatarImageVIew.image = image
                }
            }
        }
    }

    @objc private func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.set(balance: balance)
    }

    fileprivate func fetchAndUpdateBalance() {
        self.ethereumAPIClient.getBalance(address: Cereal.shared.paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                Navigator.presentModally(alertController)
            } else {
                self.set(balance: balance)
            }
        }
    }

    fileprivate func set(balance: NSDecimalNumber) {
        let attributes = self.balanceLabel.attributedText?.attributes(at: 0, effectiveRange: nil)
        let balanceString = EthereumConverter.balanceSparseAttributedString(forWei: balance, exchangeRate: EthereumAPIClient.shared.exchangeRate, width: self.balanceLabel.frame.width, attributes: attributes)

        self.balanceLabel.attributedText = balanceString
    }

    private func handleSignOut() {
        guard let currentUser = TokenUser.current else {
            let alert = UIAlertController(title: "No user found!", message: "This is an error. Please report this.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                fatalError()
            }))
            Navigator.presentModally(alert)

            return
        }

        let alert = self.alertController(balance: currentUser.balance)
        // We dispatch it back to the main thread here, even tho we are already inside the main thread
        // to avoid some weird issue where the alert controller will take seconds to present, instead of being instant.
        DispatchQueue.main.async {
            Navigator.presentModally(alert)
        }
    }

    func alertController(balance: NSDecimalNumber) -> UIAlertController {
        var alert: UIAlertController

        if self.isAccountSecured {
            alert = UIAlertController(title: "Have you secured your backup phrase?", message: "Without this you will not be able to recover your account or sign back in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Sign out", style: .destructive) { _ in
                NotificationCenter.default.post(name: .UserDidSignOut, object: nil)
            })
        } else if balance == .zero {
            alert = UIAlertController(title: "Are you sure you want to sign out?", message: "Since you have no funds and did not secure your account, it will be deleted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                NotificationCenter.default.post(name: .UserDidSignOut, object: nil)
            })
        } else {
            alert = UIAlertController(title: "Sign out cancelled", message: "You need to complete at least one of the security steps to sign out.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        }

        alert.view.tintColor = Theme.tintColor

        return alert
    }

    // MARK: TableView methods

    /// This handles the actions for cell selection.
    ///
    /// There's unfortunatelly way to directly add IBActions for touching a cell.
    ///
    func performAction(for indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // go to user profile
                self.navigationController?.pushViewController(ProfileController(), animated: true)
            case 1:
                guard let current = TokenUser.current else { return }
                let qrCodecontroller = QRCodeController(for: current.displayUsername, name: current.name)

                self.navigationController?.pushViewController(qrCodecontroller, animated: true)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 1:
                guard let current = TokenUser.current else { return }
                let controller = AddMoneyController(for: current.displayUsername, name: current.name)
                self.navigationController?.pushViewController(controller, animated: true)
            default:
                break
            }

        case 2:
            switch indexPath.row {
            case 0:
                self.navigationController?.pushViewController(BackupPhraseEnableController(), animated: true)
            case 1:
                break // trusted frieds
            default:
                break
            }

        case 3:
            switch indexPath.row {
            case 0:
                break // change currency
            case 1:
                let storyboard = UIStoryboard(name: "ProfileVisibility", bundle: nil)
                guard let profileVisiblityController = storyboard.instantiateInitialViewController() else { return }

                self.navigationController?.pushViewController(profileVisiblityController, animated: true)
            case 2:
                // go sign out
                self.handleSignOut()
            default:
                break
            }

        default:
            break
        }
    }

    open override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performAction(for: indexPath)
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 {
            let view = SettingsSectionHeader(title: "Security", error: "Your account is at risk")
            view.setErrorHidden(self.isAccountSecured, animated: false)

            return view
        }

        return super.tableView(tableView, viewForHeaderInSection: section)
    }
}
