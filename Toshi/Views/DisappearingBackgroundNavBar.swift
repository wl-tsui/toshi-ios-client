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

import SweetUIKit
import TinyConstraints
import UIKit

protocol DisappearingBackgroundNavBarDelegate: class {
    
    func didTapLeftButton(in navBar: DisappearingBackgroundNavBar)
    func didTapRightButton(in navBar: DisappearingBackgroundNavBar)
}

/// A view to allow a fake nav bar that can appear and disappear as the user scrolls, but allowing its buttons to stay in place.
class DisappearingBackgroundNavBar: UIView {
    
    private let animationSpeed = 0.25
    private let interItemSpacing: CGFloat = 8
    
    weak var delegate: DisappearingBackgroundNavBarDelegate?
    
    private lazy var leftButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.tintColor = Theme.tintColor
        button.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)

        return button
    }()
    
    private lazy var rightButton: UIButton = {
        let button = UIButton(withAutoLayout: true)
        button.tintColor = Theme.tintColor
        button.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var bottomBorder: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: false)
        
        return label
    }()
    
    private lazy var backgroundView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(withAutoLayout: true)
        visualEffectView.effect = UIBlurEffect(style: .regular)
        
        return visualEffectView
    }()
    
    // MARK: - Initialization
    
    convenience init(delegate: DisappearingBackgroundNavBarDelegate?) {
        self.init(frame: .zero)
        self.delegate = delegate
        
        setupBackground()
        setupLeftButton()
        setupRightButton()
        setupTitleLabel(leftButton: leftButton, rightButton: rightButton)
        setupBottomBorder()
    }
    
    private func setupBackground() {
        addSubview(backgroundView)
        
        backgroundView.edgesToSuperview()
        backgroundView.alpha = 0
    }
    
    private func setupLeftButton() {
        addSubview(leftButton)
        
        leftButton.leftToSuperview(offset: interItemSpacing)
        leftButton.centerYToSuperview()
        
        leftButton.isHidden = true
    }
    
    private func setupRightButton() {
        addSubview(rightButton)
        
        rightButton.rightToSuperview(offset: interItemSpacing)
        rightButton.centerYToSuperview()
        
        rightButton.isHidden = true
    }
    
    private func setupTitleLabel(leftButton: UIButton, rightButton: UIButton) {
        assert(leftButton.superview != nil)
        assert(rightButton.superview != nil)
        
        addSubview(titleLabel)
        
        titleLabel.centerYToSuperview()
        titleLabel.leftToRight(of: leftButton, offset: interItemSpacing)
        titleLabel.rightToLeft(of: rightButton, offset: interItemSpacing)
        
        titleLabel.alpha = 0
    }
    
    private func setupBottomBorder() {
        addSubview(bottomBorder)
        
        bottomBorder.edgesToSuperview(excluding: .top)
        bottomBorder.height(CGFloat.lineHeight)
        
        bottomBorder.alpha = 0
    }
    
    // MARK: - Button Images
    
    /// Sets up the left button to appear to be a back button.
    func setupLeftAsBackButton() {
        setLeftButtonImage(#imageLiteral(resourceName: "web_back"))
    }
    
    /// Takes an image, turns it into an always-template image, then sets it to the left button and un-hides the left button.
    ///
    /// - Parameter image: The image to set on the left button as a template image.
    func setLeftButtonImage(_ image: UIImage) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        leftButton.setImage(templateImage, for: .normal)
        leftButton.isHidden = false
    }
    
    /// Takes an image, turns it into an always-template image, then sets it to the right button and un-hides the right button.
    ///
    /// - Parameter image: The image to set on the right button on
    func setRightButtonImage(_ image: UIImage) {
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        rightButton.setImage(templateImage, for: .normal)
        rightButton.isHidden = false
    }
    
    func setTitle(_ text: String) {
        titleLabel.text = text
    }
    
    // MARK: - Show/Hide
    
    func showBottomBorder(_ shouldShow: Bool, animated: Bool = true) {
        showView(bottomBorder, shouldShow: shouldShow, animated: animated)
    }
    
    func showTitleLabel(_ shouldShow: Bool, animated: Bool = true) {
        showView(titleLabel, shouldShow: shouldShow, animated: animated)
    }
    
    func showBackground(_ shouldShow: Bool, animated: Bool = true) {
        showView(backgroundView, shouldShow: shouldShow, animated: animated)
    }
    
    private func showView(_ view: UIView, shouldShow: Bool, animated: Bool) {
        let duration: TimeInterval = animated ? animationSpeed : 0
        
        let targetAlpha: CGFloat
        let curve: UIViewAnimationOptions
        if shouldShow {
            targetAlpha = 1
            curve = [.curveEaseOut]
        } else {
            targetAlpha = 0
            curve = [.curveEaseIn]
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
            view.alpha = targetAlpha
        })
    }
    
    // MARK: - Action Targets
    
    @objc private func leftButtonTapped() {
        guard let delegate = delegate else {
            assertionFailure("You probably want a delegate here")
            
            return
        }
        
        delegate.didTapLeftButton(in: self)
    }
    
    @objc private func rightButtonTapped() {
        guard let delegate = delegate else {
            assertionFailure("You probably want a delegate here")
            
            return
        }
        
        delegate.didTapRightButton(in: self)
    }
}
