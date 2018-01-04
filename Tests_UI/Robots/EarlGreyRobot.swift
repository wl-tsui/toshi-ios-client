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

import EarlGrey
import Foundation
import XCTest

// MARK: - Concrete implementation of Robot pattern for Earl Grey

class EarlGreyRobot {
    
    private func viewWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_accessibilityLabel(label))
    }
    
    private func earlFromFile(file: StaticString, line: UInt) -> EarlGreyImpl {
        return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
    }
}

// MARK: - EarlGrey implementations of `BasicRobot` requirements.

extension EarlGreyRobot: BasicRobot {
    
    func confirmViewVisibleWith(accessibilityLabel: String,
                                file: StaticString,
                                line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_sufficientlyVisible())
    }
    
    func confirmViewGoneWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_notVisible())
    }

    func tapViewWith(accessibilityLabel: String,
                     file: StaticString,
                     line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }
}

// MARK: - Mix-in Robots

extension EarlGreyRobot: MyProfileRobot { /*mix-in */ }
extension EarlGreyRobot: SplashScreenRobot { /* mix-in */ }
extension EarlGreyRobot: SignInRobot { /* mix-in */ }
