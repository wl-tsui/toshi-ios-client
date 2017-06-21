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

extension UIScrollView {
    func edgeInsets(from notification: NSNotification) -> UIEdgeInsets {
        guard let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return UIEdgeInsets.zero }
        
        var keyboardFrameEnd = CGRect.zero
        value.getValue(&keyboardFrameEnd)
        keyboardFrameEnd = (self.window?.convert(keyboardFrameEnd, to: self.superview))!
        
        var newScrollViewInsets = self.contentInset
        newScrollViewInsets.bottom = self.superview!.bounds.size.height - keyboardFrameEnd.origin.y
        
        return newScrollViewInsets
    }
    
    func addBottomInsets(_ insets: UIEdgeInsets) {
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
    
    func removeBottomInsets(from notification: NSNotification) {
        let insets = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: 0.0, right: self.contentInset.right)
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
    
    func addBottomInsets(from notification: NSNotification) {
        let insets = self.edgeInsets(from: notification)
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
    
    func increaseBottomInsets(by value: CGFloat) {
        var insets = self.contentInset
        insets.bottom +=  value
        self.contentInset = insets
        self.scrollIndicatorInsets = insets
    }
    
    func decreaseBottomInsets(by value: CGFloat) {
        var insets = self.contentInset
        insets.bottom -= value
        self.contentInset = insets
        self.scrollIndicatorInsets = contentInset
    }
}
