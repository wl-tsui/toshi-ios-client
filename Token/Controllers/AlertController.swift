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

typealias ActionBlock = ((Action) -> Void)

struct Action {

    private(set) var title: String
    private(set) var titleColor: UIColor
    private(set) var icon: UIImage?
    private(set) var block: ActionBlock

    init(title: String, titleColor: UIColor = UIColor.lightGray, icon: UIImage? = nil, block: @escaping ActionBlock) {
        self.title = title
        self.titleColor = titleColor
        self.icon = icon
        self.block = block
    }
}

class AlertController: ModalPresentable {

    var customContentView: UIView? {
        didSet {
            self.arrangeCustomView()
        }
    }

    private lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView.init(withAutoLayout: true)
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.backgroundColor = Theme.greyTextColor
        stackView.spacing = 1.0

        return stackView
    }()

    lazy var reviewContainer: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    var actions = [Action]() {
        didSet {
            self.setupActionsButtons()
        }
    }

    func arrangeCustomView() {
        if let customContentView = self.customContentView as UIView? {
            self.reviewContainer.addSubview(customContentView)
            self.customContentView?.fillSuperview()
        }

        self.reviewContainer.setNeedsLayout()
        self.reviewContainer.layoutIfNeeded()

        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.init(white: 0.6, alpha: 0.7)

        self.view.addSubview(self.background)
        self.view.addSubview(self.contentView)

        self.contentView.backgroundColor = Theme.lightGreyTextColor

        self.contentView.addSubview(self.actionsStackView)
        self.contentView.addSubview(self.reviewContainer)

        self.reviewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.reviewContainer.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.reviewContainer.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.actionsStackView.topAnchor.constraint(equalTo: self.reviewContainer.bottomAnchor, constant: 1.0).isActive = true
        self.actionsStackView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.actionsStackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.actionsStackView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.background.fillSuperview()

        self.contentView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.contentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.contentView.widthAnchor.constraint(equalToConstant: PaymentConfirmationController.contentWidth).isActive = true

        self.background.addGestureRecognizer(self.tapGesture)
    }

    lazy var tapGesture: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        gestureRecognizer.cancelsTouchesInView = false

        return gestureRecognizer
    }()

    func tap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            self.dismiss(animated: true)
        }
    }

    fileprivate lazy var contentViewVerticalCenter: NSLayoutConstraint = {
        self.contentView.centerYAnchor.constraint(equalTo: self.background.centerYAnchor)
    }()

    private func setupActionsButtons() {
        for action in self.actions {
            let button = self.button(for: action)
            self.actionsStackView.addArrangedSubview(button)
        }
    }

    private func button(for action: Action) -> UIButton {
        let button = UIButton(type: .custom)
        button.set(height: 44.0)
        button.backgroundColor = Theme.viewBackgroundColor
        button.setTitle(action.title, for: .normal)
        button.setTitleColor(action.titleColor, for: .normal)
        button.setImage(action.icon, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 10.0)

        button.addTarget(self, action: #selector(actionButtonPressed(_:)), for: .touchUpInside)

        return button
    }

    @objc private func actionButtonPressed(_ button: UIButton) {
        guard let buttonIndex = self.actionsStackView.arrangedSubviews.index(of: button) as Int? else { return }
        guard self.actions.count - 1 >= buttonIndex else { return }

        let action: Action = self.actions[buttonIndex]
        action.block(action)
    }
}
