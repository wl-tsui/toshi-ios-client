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

extension UIColor {

    /// Mixes one color with the caller at a given alpha.
    ///
    /// For instance, if a designer has added a black layer at 10% opacity to a view, you can mix colors
    /// by calling this method as `color.mixedWith(.black, atAlpha: 0.1)`.
    ///
    /// Note that it looks screwy if you pass in colors with an alpha component other than the default of
    /// `1.0`, so please don't do that.
    ///
    /// - Parameters:
    ///   - otherColor: The color to blend the caller with.
    ///   - alpha: A transparency value between 0 and 1. An assertion failure will fire if this is not passed in correctly.
    /// - Returns: The blended colors
    func mixedWith(_ otherColor: UIColor, atAlpha alpha: CGFloat) -> UIColor {
        guard alpha >= 0.0 && alpha <= 1.0 else {
            assertionFailure("Please use an alpha value between 0 and 1")
            return self
        }

        let firstColorAlpha = 1.0 - alpha

        var currentRed: CGFloat = 0
        var currentGreen: CGFloat = 0
        var currentBlue: CGFloat = 0
        var currentAlpha: CGFloat = 0

        guard getRed(&currentRed, green: &currentGreen, blue: &currentBlue, alpha: &currentAlpha) else {

            assertionFailure("Could not get pointers to current color RGBA values")
            return self
        }

        var otherRed: CGFloat = 0
        var otherGreen: CGFloat = 0
        var otherBlue: CGFloat = 0
        var otherAlpha: CGFloat = 0

        guard otherColor.getRed(&otherRed, green: &otherGreen, blue: &otherBlue, alpha: &otherAlpha) else {
            assertionFailure("Could not get pointers to other color RGBA values")
            return self
        }

        let finalRed = (currentRed * firstColorAlpha) + (otherRed * alpha)
        let finalGreen = (currentGreen * firstColorAlpha) + (otherGreen * alpha)
        let finalBlue = (currentBlue * firstColorAlpha) + (otherBlue * alpha)
        let finalAlpha = (currentAlpha * firstColorAlpha) + (otherAlpha * alpha)

        return UIColor(red: finalRed, green: finalGreen, blue: finalBlue, alpha: finalAlpha)
    }
}

extension UIImage {
    func colored(with color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        let context = UIGraphicsGetCurrentContext()!

        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.multiply)

        context.draw(cgImage!, in: rect)
        context.clip(to: rect, mask: cgImage!)
        context.addRect(rect)
        context.drawPath(using: .eoFill)

        let coloredImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return coloredImg!
    }
}
