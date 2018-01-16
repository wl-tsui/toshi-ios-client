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

extension UIStackView {
    
    /// Adds given view as an arranged subview and constrains it to either the left and right or top and bottom of the caller, based on the caller's axis.
    /// A vertical stack view will cause a subview to be constrained to the left and right, since top and bottom are handled by the stack view.
    /// A horizontal stack view will cause a subview to be constrained to the top and bottom, since left and right are handled by the stack view.
    ///
    /// - Parameters:
    ///   - view: The view to add and constrain.
    ///   - margin: Any additional margin to add. Defaults to zero. Will be the same on both sides it is applied to.
    func addWithDefaultConstraints(view: UIView, margin: CGFloat = 0) {
        self.addArrangedSubview(view)
        
        switch self.axis {
        case .vertical:
            view.left(to: self, offset: margin)
            view.right(to: self, offset: -margin)
        case .horizontal:
            view.top(to: self, offset: margin)
            view.bottom(to: self, offset: -margin)
        }
    }
    
    /// Adds the given view as an arranged subview, and constrains it to the center of the opposite axis of the stack view.
    /// A vertical stack view will cause a subview to be constrained to the center X of the stackview.
    /// A horizontal stack view will cause a subview to be constrained to the center Y of the stackview.
    ///
    /// - Parameter view: The view to add and constrain.
    func addWithCenterConstraint(view: UIView) {
        self.addArrangedSubview(view)
        
        switch self.axis {
        case .vertical:
            view.centerX(to: self)
        case .horizontal:
            view.centerY(to: self)
        }
    }
    
    /// Adds a background view to force a background color to be drawn.
    /// https://stackoverflow.com/a/42256646/681493
    ///
    /// - Parameter color: The color for the background.
    func addBackground(with color: UIColor) {
        let background = UIView()
        background.backgroundColor = color
        
        self.addSubview(background)
        background.edgesToSuperview()
    }
    
    private static let spacerTag = 12345
    
    /// Backwards compatibile way to add custom spacing between views of a stack view
    /// NOTE: When iOS 11 support is dropped, this should be removed and `setCustomSpacing` should be used directly.
    ///
    /// - Parameters:
    ///   - spacing: The amount of spacing to add.
    ///   - view: The view to add the spacing after (to the right for horizontal, below for vertical)
    func addSpacing(_ spacing: CGFloat, after view: UIView) {
        if #available(iOS 11, *) {
            setCustomSpacing(spacing, after: view)
        } else {
            let spacerView = UIView()
            spacerView.tag = UIStackView.spacerTag
            spacerView.backgroundColor = .clear
            
            guard let indexOfViewToInsertAfter = self.arrangedSubviews.index(of: view) else {
                assertionFailure("You need to insert after one of the arranged subviews of this stack view!")
                return
            }
            
            insertArrangedSubview(spacerView, at: (indexOfViewToInsertAfter + 1))
            spacerView.setContentCompressionResistancePriority(.required, for: axis)

            switch axis {
            case .vertical:
                spacerView.height(spacing)
                spacerView.left(to: self)
                spacerView.right(to: self)
            case .horizontal:
                spacerView.width(spacing)
                spacerView.top(to: self)
                spacerView.bottom(to: self)
            }
        }
    }
    
    /// Removes the arranged view and any spacer view added below it.
    /// Just removes the arranged subview in iOS 11, also nukes any spacer views directly below it in iOS 10.
    ///
    /// - Parameter view: The arranged subview to remove.
    func removeArrangedSubviewAndSpacingAfter(arrangedSubview view: UIView) {
        if #available(iOS 11, *) {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        } else {
            guard let indexOfArrangedSubview = self.arrangedSubviews.index(of: view) else {
                assertionFailure("You can only do this with arranged subviews already in the view!")
                
                return
            }
            
            let spacerViewIndex = indexOfArrangedSubview + 1
            if self.arrangedSubviews.count > spacerViewIndex {
                let spacerView = arrangedSubviews[spacerViewIndex]
                if spacerView.tag == UIStackView.spacerTag {
                    removeArrangedSubview(spacerView)
                    spacerView.removeFromSuperview()
                } // else, this is not a spacer view, don't remove it.
            } // else, there is no view below the given view to remove.
            
            // In any case, remove the given view
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
