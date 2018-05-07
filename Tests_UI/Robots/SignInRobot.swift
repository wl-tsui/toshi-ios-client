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

@testable import Toshi
import XCTest

// MARK: - Robot to deal with the Sign In With Passphrase page of the app

protocol SignInRobot: BasicRobot { }

// MARK: The various buttons which are on the passphrase page

enum SignInScreenButton {
    case
    back,
    howDoesItWork,
    signIn,
    wordsLeft(words: Int)
    
    var accessibilityLabel: String {
        switch self {
        case .back:
            return Localized.back_action_title
        case .howDoesItWork:
            return Localized.passphrase_sign_in_explanation_title
        case .signIn:
            return Localized.passphrase_sign_in_button
        case .wordsLeft(let words):
            return LocalizedPlural.passphrase_sign_in_button_placeholder(for: words)
        }
    }
}

enum SignInScreenPhrases {
    case
    valid,
    invalid

    var phrase: String {
        switch self {
        case .valid:
            return "ask "
        case .invalid:
            return "marijn "
        }
    }
}

enum SignInScreenView {
    case
    error(words: Int)

    var accessibilityLabel: String {
        switch self {
        case .error(let words):
            return LocalizedPlural.passphrase_sign_in_error(for: words)
        }
    }
}

// MARK: - Default Implementation

extension SignInRobot {
    
    // MARK: - Actions
    
    @discardableResult
    func select(button: SignInScreenButton,
                file: StaticString = #file,
                line: UInt = #line) -> SignInRobot {
        tapButtonWith(accessibilityLabel: button.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateOnSignInScreen(file: StaticString = #file,
                                line: UInt = #line) -> SignInRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized.passphrase_sign_in_title,
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateOffSignInScreen(file: StaticString = #file,
                                 line: UInt = #line) -> SignInRobot {
        confirmViewGoneWith(accessibilityLabel: Localized.passphrase_sign_in_title,
                            file: file,
                            line: line)
        
        return self
    }

    @discardableResult
    func validateWordsLeftButton(wordsLeft: Int, file: StaticString = #file,
                                 line: UInt = #line) -> SignInRobot {
        confirmViewVisibleWith(accessibilityLabel: SignInScreenButton.wordsLeft(words: wordsLeft).accessibilityLabel,
                file: file,
                line: line)
        confirmButtonEnabled(false, accessibilityLabel: SignInScreenButton.wordsLeft(words: wordsLeft).accessibilityLabel,
                file: file,
                line: line)

        return self
    }

    @discardableResult
    func validateErrorForWrongWords(amount: Int, file: StaticString = #file, line: UInt = #line) -> SignInRobot {
        confirmViewVisibleWith(accessibilityLabel: SignInScreenView.error(words: amount).accessibilityLabel,
                file: file,
                line: line)

        return self
    }

    @discardableResult
    func validateErrorIsNotVisible(amount: Int, file: StaticString = #file, line: UInt = #line) -> SignInRobot {
        confirmViewGoneWith(accessibilityLabel: SignInScreenView.error(words: amount).accessibilityLabel,
                file: file,
                line: line)

        return self
    }

    @discardableResult
    func validateSignInEnabled(file: StaticString = #file, line: UInt = #line) -> SignInRobot {
        confirmButtonEnabled(true, accessibilityLabel: SignInScreenButton.signIn.accessibilityLabel,
                file: file,
                line: line)

        return self
    }

    // MARK: - Typing

    @discardableResult
    func enterValidPassPhraseWords(amount: Int, file: StaticString = #file, line: UInt = #line) -> SignInRobot {

        typeText(String(repeating: SignInScreenPhrases.valid.phrase, count: amount), onViewWith: AccessibilityIdentifier.passwordTextField,
                file: file,
                line: line)

        return self
    }

    @discardableResult
    func enterInvalidPassPhraseWords(amount: Int, file: StaticString = #file, line: UInt = #line) -> SignInRobot {
        typeText(String(repeating: SignInScreenPhrases.invalid.phrase, count: amount), onViewWith: AccessibilityIdentifier.passwordTextField,
                file: file,
                line: line)

        return self
    }

    @discardableResult
    func clearPassPhrase(file: StaticString = #file, line: UInt = #line) -> SignInRobot {

        typeText(String(repeating: "\u{8}", count: 7), onViewWith: AccessibilityIdentifier.passwordTextField,
                file: file,
                line: line)

        return self
    }
}
