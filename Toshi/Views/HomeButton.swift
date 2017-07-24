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

class HomeButton: UIControl {

    private lazy var imageContainerView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)

        view.addSubview(self.imageView)

        self.imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var subtitle: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.isUserInteractionEnabled = false

        view.font = Theme.semibold(size: 15)
        view.textColor = Theme.darkTextColor
        view.highlightedTextColor = Theme.lightGreyTextColor
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.allowsDefaultTighteningForTruncation = true

        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            self.imageView.isHighlighted = self.isHighlighted
            self.subtitle.isHighlighted = self.isHighlighted
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageContainerView)
        addSubview(subtitle)

        imageContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageContainerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageContainerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        imageContainerView.bottomAnchor.constraint(equalTo: subtitle.topAnchor).isActive = true

        subtitle.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        subtitle.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        subtitle.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.highlightedImage = image.colored(with: UIColor.black.withAlphaComponent(0.2))
    }

    func setSubtitle(_ text: String) {
        subtitle.text = text
    }
}
