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
import UserNotifications
import CameraScanner

let TabBarItemTitleOffset: CGFloat = -3.0

open class TabBarController: UITabBarController {

    public enum Tab {
        case browsing
        case messaging
        case scanner
        case favorites
        case me
    }

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    internal lazy var scannerController: ScannerViewController = {
        let controller = ScannerController(instructions: "Scan QR code", types: [.qrCode])
        controller.delegate = self

        return controller
    }()

    internal lazy var placeholderScannerController: UIViewController = {
        let controller = UIViewController()
        controller.tabBarItem = UITabBarItem(title: "Scan", image: #imageLiteral(resourceName: "scan"), tag: 0)
        controller.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        return controller
    }()

    internal var browseController: BrowseNavigationController!
    internal var messagingController: ChatsNavigationController!
    internal var favoritesController: FavoritesNavigationController!
    internal var settingsController: SettingsNavigationController!

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.delegate = self
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Refactor all this navigation controllers subclasses into one, they have similar code
        self.browseController = BrowseNavigationController(rootViewController: BrowseController())
        self.favoritesController = FavoritesNavigationController(rootViewController: FavoritesController())

        self.messagingController = ChatsNavigationController(nibName: nil, bundle: nil)
        let chatsController = ChatsController()

        if let address = UserDefaults.standard.string(forKey: self.messagingController.selectedThreadAddressKey), let thread = chatsController.thread(withAddress: address) as TSThread? {
            self.messagingController.viewControllers = [chatsController, ChatController(thread: thread)]
        } else {
            self.messagingController.viewControllers = [chatsController]
        }

        self.settingsController = SettingsNavigationController(rootViewController: SettingsController.instantiateFromNib())

        self.viewControllers = [
            self.browseController,
            self.messagingController,
            self.placeholderScannerController,
            self.favoritesController,
            self.settingsController,
        ]

        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor
        self.tabBar.unselectedItemTintColor = Theme.unselectedItemTintColor

        let index = UserDefaults.standard.integer(forKey: self.tabBarSelectedIndexKey)
        self.selectedIndex = index
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.presentAddressChangeAlertIfNeeded()
    }

    func openPaymentMessage(to address: String, parameters: [String: Any]? = nil) {
        self.dismiss(animated: false) {

            ChatsController.getOrCreateThread(for: address)

            DispatchQueue.main.async {
                self.displayMessage(forAddress: address) { controller in
                    if let chatController = controller as? ChatController, let parameters = parameters as [String: Any]? {
                        chatController.sendPayment(with: parameters)
                    }
                }
            }
        }
    }

    private func presentAddressChangeAlertIfNeeded() {
        guard UserDefaults.standard.bool(forKey: AddressChangeAlertShown) == false else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alertController = AddressChangeAlertController()
            alertController.modalPresentationStyle = .custom
            alertController.transitioningDelegate = alertController

            self.selectedViewController?.present(alertController, animated: true, completion: nil)

            UserDefaults.standard.set(true, forKey: AddressChangeAlertShown)
            UserDefaults.standard.synchronize()
        }
    }

    public func displayMessage(forAddress address: String, completion: ((Any?) -> Void)? = nil) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address, completion: completion)
    }

    public func `switch`(to tab: Tab) {
        switch tab {
        case .browsing:
            self.selectedIndex = 0
        case .messaging:
            self.selectedIndex = 1
        case .scanner:
            self.presentScanner()
        case .favorites:
            self.selectedIndex = 3
        case .me:
            self.selectedIndex = 4
        }
    }

    fileprivate func presentScanner() {
        SoundPlayer.playSound(type: .menuButton)
        self.present(self.scannerController, animated: true)
    }

    public func openDeepLinkURL(_ url: URL) {
        if url.user == "username" {
            guard let username = url.host else { return }

            self.idAPIClient.retrieveContact(username: username) { contact in
                guard let contact = contact else { return }

                let contactController = ContactController(contact: contact)
                (self.selectedViewController as? UINavigationController)?.pushViewController(contactController, animated: true)
            }
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController == self.placeholderScannerController {
            self.presentScanner()

            return false
        }

        return true
    }

    public func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        SoundPlayer.playSound(type: .menuButton)

        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        if let index = self.viewControllers?.index(of: viewController) {
            UserDefaults.standard.set(index, forKey: self.tabBarSelectedIndexKey)
        }
    }
}

extension TabBarController: ScannerViewControllerDelegate {

    public func scannerViewControllerDidCancel(_: ScannerViewController) {
        self.dismiss(animated: true)
    }

    public func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        if result.hasPrefix("web-signin:") {
            let login_token = result.substring(from: result.index(result.startIndex, offsetBy: 11))
            self.idAPIClient.login(login_token: login_token) { _, _ in
                self.dismiss(animated: true)
            }
        } else {
            guard let url = URL(string: result) as URL? else { return }
            let path = url.path

            if path.hasPrefix("/add") {
                let username = result.replacingOccurrences(of: QRCodeController.addUsernameBasePath, with: "")
                let contactName = TokenUser.name(from: username)

                self.idAPIClient.retrieveContact(username: contactName) { contact in
                    guard let contact = contact else {
                        controller.startScanning()

                        return
                    }

                    SoundPlayer.playSound(type: .scanned)

                    self.dismiss(animated: true) {
                        self.switch(to: .favorites)
                        let contactController = ContactController(contact: contact)
                        self.favoritesController.pushViewController(contactController, animated: true)
                    }
                }

            } else {
                self.proceedToPayment(with: url)
            }
        }
    }

    fileprivate func proceedToPayment(with url: URL) {
        let path = url.path
        var username = ""

        var userInfo: UserInfo?
        var parameters = ["from": Cereal.shared.paymentAddress]

        if path.hasPrefix(QRCodeController.paymentWithAddressPath) {
            username = path.replacingOccurrences(of: QRCodeController.paymentWithAddressPath, with: "")
        } else if path.hasPrefix(QRCodeController.paymentWithUsernamePath) {
            username = path.replacingOccurrences(of: QRCodeController.paymentWithUsernamePath, with: "")
            username = TokenUser.name(from: username)
        }

        guard username.length > 0 else {
            self.scannerController.startScanning()

            return
        }

        self.idAPIClient.retrieveContact(username: username) { contact in
            if let contact = contact as TokenUser? {
                userInfo = contact.userInfo
                parameters["to"] = contact.paymentAddress

                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.contactsManager.refreshContacts()

            } else {
                userInfo = UserInfo(address: username, paymentAddress: contact?.paymentAddress, avatarPath: nil, name: nil, username: username, isLocal: false)
                parameters["to"] = username
            }

            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            if let queryItems = components.queryItems {
                for item in queryItems {
                    if item.name == "value", let value = item.value {

                        let ether = NSDecimalNumber(string: value)
                        let valueInWei = ether.multiplying(byPowerOf10: EthereumConverter.weisToEtherPowerOf10Constant)

                        parameters["value"] = valueInWei.toHexString

                        break
                    }
                }
            }

            if let scannerController = self.scannerController as? PaymentPresentable {
                scannerController.displayPaymentConfirmation(userInfo: userInfo!, parameters: parameters)
            }
        }
    }
}
