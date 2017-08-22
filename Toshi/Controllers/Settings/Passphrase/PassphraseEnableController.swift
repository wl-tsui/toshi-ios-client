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

class PassphraseEnableController: UIViewController {

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel(Localized("passphrase_enable_title"))

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = TextLabel(Localized("passphrase_enable_text"))

        return view
    }()

    lazy var checkboxControl: CheckboxControl = {
        let text = Localized("passphrase_enable_checkbox")

        let view = CheckboxControl(withAutoLayout: true)
        view.title = text
        view.addTarget(self, action: #selector(checked(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.title = Localized("passphrase_enable_action")
        view.isEnabled = false
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)

        return view
    }()

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public init() {
        super.init(nibName: nil, bundle: nil)

        title = Localized("passphrase_enable_navigation_title")
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.settingsBackgroundColor

        view.addSubview(titleLabel)
        view.addSubview(textLabel)
        view.addSubview(checkboxControl)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40 + 64),
            self.titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.textLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.checkboxControl.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 30),
            self.checkboxControl.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.checkboxControl.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.actionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
        ])
    }

    func checked(_ checkboxControl: CheckboxControl) {
        checkboxControl.checkbox.checked = !checkboxControl.checkbox.checked
        actionButton.isEnabled = checkboxControl.checkbox.checked
    }
    
    func proceed(_: ActionButton) {
        let controller = PassphraseCopyController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
