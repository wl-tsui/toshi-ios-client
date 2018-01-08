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
@testable import Toshi
import XCTest

class AccountCreateUITests: XCTestCase {
    
    lazy var myProfileRobot: MyProfileRobot = EarlGreyRobot()
    lazy var signInRobot: SignInRobot = EarlGreyRobot()
    lazy var splashRobot: SplashScreenRobot = EarlGreyRobot()
    lazy var tabBarRobot: TabBarRobot = EarlGreyRobot()
    
    // MARK: - Tests
    
    // MARK: Account Creation
    
    func testCreateAccountThenCancel() {
        self.splashRobot
            .validateOnSplashScreen()
            .select(button: .createNewAccount)
            .validateTermsDialogShowing()
            .select(termsOption: .cancel)
            .validateTermsDialogGone()
            .validateOnSplashScreen()
    }
    
    func testCreateAccountThenAgree() {
        self.splashRobot
            .validateOnSplashScreen()
            .select(button: .createNewAccount)
            .validateTermsDialogShowing()
            .select(termsOption: .agree)
            .validateTermsDialogGone()
            .validateOffSplashScreen()
        
        self.tabBarRobot
            .validateTabBarShowing()
            .select(item: .me)
    
        self.myProfileRobot
            .validateOnMyProfileScreen()
            .select(cell: .signOut)
            .validateNoFundsSignOutDialogShowing()
            .select(signOutOption: .delete)
            .validateNoFundsSignOutDialogGone()
    }
    
    func testCreateAccountThenReadTerms() {
        guard let expectedTermsURL = URL(string: "http://www.toshi.org/terms-of-service/") else {
            XCTFail("Could not create terms URL!")
            return
        }
        
        self.splashRobot
            .validateOnSplashScreen()
            .select(button: .createNewAccount)
            .validateTermsDialogShowing()
            .select(termsOption: .read)
            .validateTermsDialogGone()
            .validateTestAlertShowing(withMessage: TestOnlyString.readTermsAlertMessage(termsURL: expectedTermsURL))
            .dismissTestAlert()
            .validateTestAlertGone()
            
            // TODO: Re-enable below when Earl Grey figures their shit out with SFSafariViewController.
//            .validateFullTermsShowing()
//            .select(termsScreenOption: .done)
//            .validateFullTermsGone()
//            .validateTermsDialogShowing()
//            // Dismiss the dialog for the next test.
//            .select(termsOption: .cancel)
//            .validateTermsDialogGone()
    }
    
    func testSignIn() {
        self.splashRobot
            .validateOnSplashScreen()
            .select(button: .signIn)
            .validateOffSplashScreen()
        
        self.signInRobot
            .validateOnSignInScreen()
            
            // Go back to splash for next test
            .select(button: .back)
            .validateOffSignInScreen()
    }
}
