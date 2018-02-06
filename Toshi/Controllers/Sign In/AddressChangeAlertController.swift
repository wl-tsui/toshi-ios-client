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
import UIKit
import SweetUIKit

let alertText = "We have made changes to make\nToshi compatible with other\nservices - as a result your\nbalance will appear to be reset.\nAs this is only testnet ETH,\n you don't need to take any action.\nIf you do want to recover your\nbalance for any reason, you can\nread how to do it here: http://developers.toshi.org/"

final class AddressChangeAlertController: AlertController {

    private lazy var textView: UITextView = {
        let textView = UITextView(withAutoLayout: true)
        textView.dataDetectorTypes = [.all]
        textView.text = alertText
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 15.0)
        textView.textAlignment = .center

        return textView
    }()

    private lazy var content: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = UIFont.systemFont(ofSize: 19.0)
        label.text = "Toshi Address Changes"
        label.textColor = Theme.tintColor
        label.textAlignment = .center

        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        visualEffectView.backgroundColor = Theme.viewBackgroundColor
        visualEffectView.widthAnchor.constraint(equalToConstant: 270.0).isActive = true

        content.addSubview(titleLabel)
        titleLabel.set(height: 27.0)
        titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true

        content.addSubview(textView)

        textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true

        content.set(height: 230.0)

        customContentView = content

        let action = Action(title: Localized("continue_action_title"), titleColor: Theme.tintColor) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        actions = [action]
    }
}
