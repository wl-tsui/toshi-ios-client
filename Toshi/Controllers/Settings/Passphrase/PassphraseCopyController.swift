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

class PassphraseCopyController: UIViewController {

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel(Localized("passphrase_copy_title"))

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = TextLabel(Localized("passphrase_copy_text"))
        view.textAlignment = .center

        return view
    }()

    private lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.title = Localized("passphrase_copy_action")
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var passphraseView = PassphraseView(with: Cereal.shared.mnemonic!.words, for: .original)

    private lazy var confirmationButton: ConfirmationButton = {
        let view = ConfirmationButton(withAutoLayout: true)
        view.title = Localized("passphrase_copy_confirm_title")
        view.confirmation = Localized("passphrase_copy_confirm_copied")
        view.addTarget(self, action: #selector(copyToClipBoard(_:)), for: .touchUpInside)

        return view
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)

        title = Localized("passphrase_copy_navigation_title")
        hidesBottomBarWhenPushed = true
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.settingsBackgroundColor

        view.addSubview(titleLabel)
        view.addSubview(textLabel)
        view.addSubview(passphraseView)
        view.addSubview(confirmationButton)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40 + 64),
            self.titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.textLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.passphraseView.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 60),
            self.passphraseView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15),
            self.passphraseView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15),

            self.confirmationButton.topAnchor.constraint(equalTo: self.passphraseView.bottomAnchor, constant: 20),
            self.confirmationButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),

            self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.actionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }

    @objc func proceed(_: ActionButton) {
        let controller = PassphraseVerifyController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func copyToClipBoard(_ button: ConfirmationButton) {

        UIPasteboard.general.string = Cereal.shared.mnemonic!.words.joined(separator: " ")

        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            button.contentState = button.contentState == .actionable ? .confirmation : .actionable
        }
    }
}
