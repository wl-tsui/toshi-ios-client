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
    
    /// Adds given view as an arranged subview standard-pins it based on the axis of the stack view.
    /// A vertical stack view will cause a subview to be pinned to the left and right, since top and bottom are handled by the stack view
    /// A horizontal stack view will cause a subview to be pinned to the top and bottom, since left and right are handled by the stack view.
    ///
    /// - Parameters:
    ///   - view: The view to add and pin.
    ///   - margin: Any additional margin to add. Defaults to zero. Will be the same on both sides it is applied to.
    func addAndStandardPin(view: UIView, margin: CGFloat = 0) {
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
    
    /// Adds the given view as an arranged subview, and pins it to the center of the opposite axis of the stack view.
    /// A vertical stack view will cause a subview to be pinned to the center X of the stackview.
    /// A horizontal stack view will cause a subview to be pinned to the center Y of the stackview.
    ///
    /// - Parameter view: The view to add and pin.
    func addAndCenterPin(view: UIView) {
        self.addArrangedSubview(view)
        
        switch self.axis {
        case .vertical:
            view.centerX(to: self)
        case .horizontal:
            view.centerY(to: self)
        }
    }
}
