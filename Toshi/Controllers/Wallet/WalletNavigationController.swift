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

import Foundation

class WalletNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_wallet"), image: #imageLiteral(resourceName: "tab3"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationBar.prefersLargeTitles = true
        }

        self.navigationBar.barTintColor = Theme.tintColor
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: Theme.lightTextColor ]
    }
}
