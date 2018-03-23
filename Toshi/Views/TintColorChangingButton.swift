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

import UIKit

/// A button which automatically updates its tint color based on the button's current state. 
final class TintColorChangingButton: UIButton {

    private let normalTintColor: UIColor
    private let disabledTintColor: UIColor
    private let selectedTintColor: UIColor
    private let highlightedTintColor: UIColor

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - normalTintColor: The color the button should be when enabled. Defaults to the theme color.
    ///   - disabledTintColor: The color the button should be when disabled. Defaults to a gray color.
    ///   - selectedTintColor: [Optional] The color the button should be when selected.
    ///                        If nil, the `normalTintColor` will be used. Defaults to nil.
    ///   - highlightedTintColor: [Optional] The color the button should be when highlighted.
    ///                           If nil, the `normalTintColor` will be use. Defaults to nil.
    init(normalTintColor: UIColor = Theme.tintColor,
         disabledTintColor: UIColor = Theme.greyTextColor,
         selectedTintColor: UIColor? = nil,
         highlightedTintColor: UIColor? = nil) {
        self.normalTintColor = normalTintColor
        self.disabledTintColor = disabledTintColor
        self.selectedTintColor = selectedTintColor ?? normalTintColor
        self.highlightedTintColor = highlightedTintColor ?? normalTintColor

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isEnabled: Bool {
        didSet {
            updateTintColor()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            updateTintColor()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateTintColor()
        }
    }

    private func updateTintColor() {
        switch state {
        case .normal:
            tintColor = normalTintColor
        case .disabled:
            tintColor = disabledTintColor
        case .selected:
            tintColor = selectedTintColor
        case .highlighted:
            tintColor = highlightedTintColor
        default:
            // some state combo is happening, leave things where they are
            break
        }
    }
}
