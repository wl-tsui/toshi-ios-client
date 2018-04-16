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
import UIKit
@testable import Toshi
import XCTest

// MARK: - Concrete implementation of Robot pattern for Earl Grey

class EarlGreyRobot {
    
    private func retriveElementOfClass<T>(_ clazz: T.Type, _ completion: @escaping (T?) -> Void) -> GREYActionBlock where T: AnyObject {
        return GREYActionBlock(name: "Get element of class \(T.self)",
            constraints: grey_kindOfClass(T.self),
            perform: { element, _ in
                guard let typedElement = element as? T else {
                    return false
                }
                
                completion(typedElement)
                return true
        })
    }
    
    private func viewWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        // Accessibility replaces newlines with spaces.
        let labelWithoutNewlines = label.replacingOccurrences(of: "\n", with: " ")
        
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_accessibilityLabel(labelWithoutNewlines)
            ]))
            .atIndex(0)
    }
    
    private func buttonWith(label: String,
                            file: StaticString,
                            line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_accessibilityLabel(label),
                grey_accessibilityTrait(UIAccessibilityTraitButton)
            ]))
            .atIndex(0)
    }

    private func textFieldWith(placeHolder: String, file: StaticString, line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_kindOfClass(UITextField.self),
                matcher(forPlaceholder: placeHolder)
            ]))
            .atIndex(0)
    }

    private func cellWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return self.earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_descendant(grey_accessibilityLabel(label)),
                grey_sufficientlyVisible(),
                grey_kindOfClass(UITableViewCell.self)
            ]))
            .usingSearch(grey_scrollInDirection(.down, 100),
                         onElementWith: grey_kindOfClass(UITableView.self))

    }

    private func itemWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return self.earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_descendant(grey_accessibilityLabel(label)),
                grey_sufficientlyVisible(),
                grey_kindOfClass(UICollectionViewCell.self)
            ]))
            .usingSearch(grey_scrollInDirection(.down, 100),
                         onElementWith: grey_kindOfClass(UICollectionViewCell.self))

    }
    
    private func viewWith(identifier: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_accessibilityID(identifier))
    }
    
    private func earlFromFile(file: StaticString, line: UInt) -> EarlGreyImpl {
        return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
    }
}

// MARK: - EarlGrey implementations of `BasicRobot` requirements.

extension EarlGreyRobot: BasicRobot {
    
    func confirmViewVisibleWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_sufficientlyVisible())
    }
    
    func confirmViewVisibleWith(accessibilityIdentifier: AccessibilityIdentifier, file: StaticString, line: UInt) {
        viewWith(identifier: accessibilityIdentifier.rawValue, file: file, line: line)
            .assert(with: grey_sufficientlyVisible())
    }

    func confirmTextFieldVisibleWith(placeHolder: String, file: StaticString, line: UInt) {
        textFieldWith(placeHolder: placeHolder, file: file, line: line)
                .assert(with: grey_sufficientlyVisible())
    }

    func confirmViewGoneWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_notVisible())
    }
    
    func confirmViewGoneWith(accessibilityIdentifier: AccessibilityIdentifier, file: StaticString, line: UInt) {
        viewWith(identifier: accessibilityIdentifier.rawValue, file: file, line: line)
            .assert(with: grey_notVisible())
    }

    func confirmTextFieldGoneWith(placeHolder: String, file: StaticString, line: UInt) {
        textFieldWith(placeHolder: placeHolder, file: file, line: line)
                .assert(with: grey_notVisible())
    }

    func tapButtonWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        buttonWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }
    
    func tapCellWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        cellWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }

    func tapViewWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }

    func typeText(_ text: String, onViewWith accessibilityIdentifier: AccessibilityIdentifier, file: StaticString, line: UInt) {
        viewWith(identifier: accessibilityIdentifier.rawValue, file: file, line: line)
            .perform(grey_typeText(text))
    }

    func clearText(onTextFieldWith placeholder: String, file: StaticString, line: UInt) {
        textFieldWith(placeHolder: placeholder, file: file, line: line)
                .perform(grey_clearText())
    }

    func confirmButtonEnabled(_ enabled: Bool, accessibilityLabel: String, file: StaticString, line: UInt) {
        if enabled {
            viewWith(label: accessibilityLabel, file: file, line: line).assert(with: grey_enabled())
        } else {
            viewWith(label: accessibilityLabel, file: file, line: line).assert(with: grey_not(grey_enabled()))
        }
    }
}

/// Extensions for accessing weirdly annotated objc things
extension GREYInteraction {
    @discardableResult public func assert(with matcher: @autoclosure () -> GREYMatcher) -> Self {
        return self.__assert(with: matcher())
    }

    @discardableResult public func assert(_ matcher: @autoclosure () -> GREYMatcher,
                                          error: UnsafeMutablePointer<NSError?>!) -> Self {
        return self.__assert(with: matcher(), error: error)
    }

    @discardableResult public func perform(_ action: GREYAction!) -> Self {
        return self.__perform(action)
    }
}

// MARK: - Mix-in Robots

extension EarlGreyRobot: MyProfileRobot { /*mix-in */ }
extension EarlGreyRobot: SplashScreenRobot { /* mix-in */ }
extension EarlGreyRobot: SignInRobot { /* mix-in */ }
extension EarlGreyRobot: TabBarRobot { /* mix-in */ }
extension EarlGreyRobot: HowDoesItWorkScreenRobot { /* mix-in */ }

/**
*  Matcher for UI element with the provided accessibility @c label.
*
*  @param label The accessibility label to be matched.
*
*  @return A matcher for the accessibility label of an accessible element.
*/
func matcher(forPlaceholder placeholder: String) -> GREYMatcher {
    return GREYElementMatcherBlock(matchesBlock: { element in
        guard let textField = element as? UITextField else { return false }

        return textField.placeholder == placeholder
    }, descriptionBlock: { description in
        guard let description = description else { return }

        description.appendText("has placeholder \(placeholder)")
    })
}
