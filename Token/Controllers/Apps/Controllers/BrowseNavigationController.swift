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

public class BrowseNavigationController: UINavigationController {

    static let selectedAppKey = "Restoration::SelectedApp"

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.tabBarItem = UITabBarItem(title: "Browse", image: #imageLiteral(resourceName: "browse"), tag: 0)
        self.tabBarItem.selectedImage = #imageLiteral(resourceName: "browse-selected")
        self.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: move restoration to the tabbar controller, so we only restore the currently selected.
        if let appData = UserDefaults.standard.data(forKey: BrowseNavigationController.selectedAppKey) {
            // we delay by one cycle and it's enough for UIKit to set the children viewcontrollers
            // for the navigation controller. Otherwise `viewcontrollers` will be nil and it wont restore.
            // Downside: it blinks the previous view for no.
            // TODO: move all of this the the navigator so we can restore the hiararchy straight from the app delegate.
            DispatchQueue.main.asyncAfter(seconds: 0.0) {
                guard let json = try? JSONSerialization.jsonObject(with: appData, options: []), let appJson = json as? [String: Any] else { return }
                let appController = ContactController(contact: TokenUser(json: appJson))

                self.pushViewController(appController, animated: false)
            }
        }
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ContactController {
            UserDefaults.standard.setValue(viewController.contact.JSONData, forKey: BrowseNavigationController.selectedAppKey)
        }
    }

    public override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaults.standard.removeObject(forKey: BrowseNavigationController.selectedAppKey)
        return super.popViewController(animated: animated)
    }

    public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaults.standard.removeObject(forKey: BrowseNavigationController.selectedAppKey)
        return super.popToRootViewController(animated: animated)
    }

    public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaults.standard.removeObject(forKey: BrowseNavigationController.selectedAppKey)
        return super.popToViewController(viewController, animated: animated)
    }
}
