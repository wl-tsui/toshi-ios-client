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

protocol Emptiable: class {
    func sourceView() -> UIView
    func isScrollable() -> Bool

    var buttonPressed: Selector { get }

    func emptyStateTitle() -> String
    func emptyStateDescription() -> String
    func emptyStateButtonTitle() -> String

    func contentCenterVerticalOffset() -> CGFloat

    func adjustEmptyView()
    func makeEmptyView(hidden: Bool)
}

extension Emptiable where Self: UIViewController {

    func makeEmptyView(hidden: Bool) {
        let sourceView = self.sourceView()
        sourceView.isHidden = hidden
    }

    func contentCenterVerticalOffset() -> CGFloat {
        return 0.0
    }

    func adjustEmptyView() {
        let sourceView = self.sourceView()

        let containerView = UIView(withAutoLayout: true)
        containerView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        containerView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        let titleLabel = self.label(with: Theme.medium(size: 20.0))
        let descriptionLabel = self.label(with: Theme.regular(size: 16.0))

        let scrollView = self.scrollView()
        sourceView.addSubview(scrollView)
        scrollView.fillSuperview()

        scrollView.addSubview(containerView)

        let verticalOffset = contentCenterVerticalOffset()
        containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: verticalOffset).isActive = true
        containerView.set(width: sourceView.bounds.width - 30.0)

        containerView.addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true

        containerView.addSubview(descriptionLabel)
        descriptionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0).isActive = true

        let button = self.actionButton()

        if let buttonTitle = self.emptyStateButtonTitle() as String? {
            containerView.addSubview(button)
            button.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30.0).isActive = true
            button.set(height: 44.0)
            button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

            button.setTitle(buttonTitle, for: .normal)
        } else {
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        }

        titleLabel.text = emptyStateTitle()

        let attributedString = NSMutableAttributedString(string: emptyStateDescription())
        let paragraphStyle = NSMutableParagraphStyle()

        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 3
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

        descriptionLabel.attributedText = attributedString
    }

    func scrollView() -> UIScrollView {
        let scrollView = UIScrollView(withAutoLayout: true)
        scrollView.backgroundColor = UIColor.white
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = isScrollable()
        scrollView.contentSize = sourceView().frame.size

        return scrollView
    }

    func actionButton() -> UIButton {
        let button = UIButton(withAutoLayout: true)
        button.backgroundColor = Theme.tintColor
        button.titleLabel?.font = Theme.medium(size: 16.0)
        button.layer.cornerRadius = 5.0
        button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0.0, right: 30.0)

        button.addTarget(self, action: buttonPressed, for: .touchUpInside)

        return button
    }

    func label(with font: UIFont) -> UILabel {
        let label = UILabel(withAutoLayout: true)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = font

        label.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        return label
    }
}
