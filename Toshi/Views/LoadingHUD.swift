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

import TinyConstraints
import UIKit

/// A Heads-Up display for loading and success.
final class LoadingHUD: UIView {

    enum HUDState {
        case
        /// - text: [optional] Any text to show below the loading indicator
        loading(text: String?),
        /// - image: The image to show on success. Will be displayed in template mode automatically.
        /// - text: [optional] Any text to show below the success image
        success(image: UIImage, text: String?)
    }

    /// The current state of the HUD.
    var state: HUDState = .loading(text: nil) {
        didSet {
            configure(for: state)
        }
    }

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = .gray
        indicator.startAnimating()

        return indicator
    }()

    private lazy var successImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.tintColor = Theme.tintColor

        let imageViewSize: CGFloat = 56
        imageView.height(imageViewSize)
        imageView.width(imageViewSize)

        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.tintColor
        label.font = Theme.preferredRegularText()
        label.numberOfLines = 0
        label.textAlignment = .center

        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = .mediumInterItemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    /// Designated initializer.
    ///
    /// - Parameter superview: The superview the HUD should be added to.
    init(addedToView superview: UIView) {
        super.init(frame: .zero)

        superview.addSubview(self)
        edgesToSuperview()

        backgroundColor = Theme.viewBackgroundColor.withAlphaComponent(0.95)

        addSubview(stackView)
        stackView.centerXToSuperview()
        stackView.centerYToSuperview()

        configure(for: state, animated: false)
    }

    // MARK: - State Handling

    private func configure(for state: HUDState, animated: Bool = true) {
        stackView.removeAllArrangedSubviews()
        switch state {
        case .loading(let optionalText):
            stackView.addArrangedSubview(loadingIndicator)
            if let text = optionalText {
                stackView.addArrangedSubview(textLabel)
                textLabel.text = text
            }
        case .success(let image, let optionalText):
            stackView.addArrangedSubview(successImageView)
            successImageView.image = image.withRenderingMode(.alwaysTemplate)
            if let text = optionalText {
                stackView.addArrangedSubview(textLabel)
                textLabel.text = text
            }
        }

        UIView.animate(withDuration: animated ? 0.1 : 0.0, animations: {
            self.stackView.layoutIfNeeded()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use the other initializer!")
    }

    // MARK: - Animation

    /// Shows the HUD.
    ///
    /// - Parameter completion: [optional] The completion block to execute when showing is complete. Defaults to nil.
    func show(completion: (() -> Void)? = nil) {
        setShowing(true, completion: completion)
    }

    /// Hides the HUD
    ///
    /// - Parameter completion: [optional] The completion block to execute when hiding is complete. Defaults to nil.
    func hide(completion: (() -> Void)? = nil) {
        setShowing(false, completion: completion)
    }

    /// Shows the success state then hides the hud after a given delay
    ///
    /// - Parameters:
    ///   - delay: The delay after showing success to hide the HUD. Defaults to 2 seconds.
    ///   - image: The image to show on success
    ///   - text: [optional] The text to show on success
    ///   - completion: [optional] The completion block to execute when hiding is complete. Defaults to nil.
    func successThenHide(after delay: TimeInterval = 2,
                         image: UIImage,
                         text: String?,
                         completion: (() -> Void)? = nil) {
        state = .success(image: image, text: text)
        setShowing(false,
                   after: delay,
                   completion: {
                    self.removeFromSuperview()
                    completion?()
                   })
    }

    private func setShowing(_ showing: Bool, after delay: TimeInterval = 0, completion: (() -> Void)?) {
        let alpha: CGFloat = showing ? 1 : 0
        let curve: UIViewAnimationOptions = showing ? .curveEaseOut : .curveEaseIn

        UIView.animate(withDuration: 0.4,
                       delay: delay,
                       options: curve,
                       animations: {
                        self.alpha = alpha
                       },
                       completion: { _ in
                        completion?()
                       })
    }
}
