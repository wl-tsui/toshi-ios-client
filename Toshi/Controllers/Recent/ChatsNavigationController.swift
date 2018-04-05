// Copyright (c) 2018 Token Browser, Inc
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

final class ChatsNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (topViewController == viewControllers.first) ? .lightContent : .default
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized.tab_bar_title_chats, image: ImageAsset.tab2, tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    func openThread(withAddress address: String, completion: ((Any?) -> Void)? = nil) {
        _ = popToRootViewController(animated: false)
        guard let chatsViewController = self.viewControllers.first as? ChatsViewController else { return }

        if let thread = chatsViewController.thread(withAddress: address) {
            let chatViewController = ChatViewController(thread: thread)
            pushViewController(chatViewController, animated: false)

            completion?(chatViewController)
        } else {
            completion?(nil)
        }
    }

    func openThread(withThreadIdentifier identifier: String, animated: Bool) {
        _ = self.popToRootViewController(animated: animated)
        guard let chatsViewController = self.viewControllers.first as? ChatsViewController else { return }
        guard let thread = chatsViewController.thread(withIdentifier: identifier) else { return }

        let chatViewController = ChatViewController(thread: thread)
        self.pushViewController(chatViewController, animated: animated)
    }

    func openThread(_ thread: TSThread, animated: Bool) {
        let chatViewController = ChatViewController(thread: thread)
        self.pushViewController(chatViewController, animated: animated)
    }

    // MARK: - Nav Bar Color Handling

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let colorable = viewController as? NavBarColorChanging {
            setNavigationBarColors(with: colorable)
        }

        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ChatViewController {
            UserDefaultsWrapper.selectedThreadAddress = viewController.thread.contactIdentifier()
        }
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedThreadAddress = nil

        return super.popToRootViewController(animated: animated)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedThreadAddress = nil

        return super.popToViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
         UserDefaultsWrapper.selectedThreadAddress = nil

        guard let colorChangingVC = previousViewController as? NavBarColorChanging else {
            // Just call super and be done with it.
            return super.popViewController(animated: animated)
        }

        setNavigationBarColors(with: colorChangingVC)

        // Start the transition by calling super so we get a transition coordinator
        let poppedViewController = super.popViewController(animated: animated)

        transitionCoordinator?.animate(alongsideTransition: nil, completion: { [weak self] _ in
            guard let topColorChangingVC = self?.topViewController as? NavBarColorChanging else { return }
            self?.setNavigationBarColors(with: topColorChangingVC)
        })

        return poppedViewController
    }

    private var previousViewController: UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[viewControllers.count - 2]
    }

    private func setNavigationBarColors(with colorChangingObject: NavBarColorChanging) {
        navigationBar.tintColor = colorChangingObject.navTintColor
        navigationBar.barTintColor = colorChangingObject.navBarTintColor
        navigationBar.shadowImage = colorChangingObject.navShadowImage
        if let titleColor = colorChangingObject.navTitleColor {
            navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: titleColor]
        } else {
            navigationBar.titleTextAttributes = nil
        }
    }
}
