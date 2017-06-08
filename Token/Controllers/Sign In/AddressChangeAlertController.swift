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

import Foundation
import UIKit
import SweetUIKit

extension NSString {
    static func addressChangeAlertShown() -> String { return AddressChangeAlertShown }
}

let AddressChangeAlertShown = "AddressChangeAlertShown"

let alertText = "We have made changes to make\nToken compatible with other\nservices - as a result your\nbalance will appear to be reset.\nAs this is only testnet ETH,\n you don't need to take any action.\nIf you do want to recover your\nbalance for any reason, you can\nread how to do it here: http://developers.tokenbrowser.com/"

final class AddressChangeAlertController: AlertController {

    fileprivate lazy var textView: UITextView = {
        let textView = UITextView(withAutoLayout: true)
        textView.dataDetectorTypes = [.all]
        textView.text = alertText
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 15.0)
        textView.textAlignment = .center

        return textView
    }()

    fileprivate lazy var content: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = UIFont.systemFont(ofSize: 19.0)
        label.text = "Token Address Changes"
        label.textColor = Theme.tintColor
        label.textAlignment = .center

        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clear

        self.contentView.backgroundColor = Theme.viewBackgroundColor
        self.contentView.widthAnchor.constraint(equalToConstant: 270.0).isActive = true

        self.content.addSubview(self.titleLabel)
        self.titleLabel.set(height: 27.0)
        self.titleLabel.topAnchor.constraint(equalTo: self.content.topAnchor, constant: 10.0).isActive = true
        self.titleLabel.leftAnchor.constraint(equalTo: self.content.leftAnchor).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.content.rightAnchor).isActive = true

        self.content.addSubview(self.textView)

        self.textView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor).isActive = true
        self.textView.leftAnchor.constraint(equalTo: self.content.leftAnchor).isActive = true
        self.textView.rightAnchor.constraint(equalTo: self.content.rightAnchor).isActive = true
        self.textView.bottomAnchor.constraint(equalTo: self.content.bottomAnchor).isActive = true

        self.content.set(height: 230.0)

        self.customContentView = self.content

        let action = Action.init(title: "Continue", titleColor: Theme.tintColor) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        self.actions = [action]
    }
}
