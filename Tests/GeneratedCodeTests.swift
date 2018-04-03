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

@testable import Toshi
import XCTest

class GeneratedCodeTests: XCTestCase {

    /// An enum representing all currently supported languages.
    /// Each key should be the name of the .lproj file so localized strings can be loaded
    /// regardless of the language of the device or sim running the tests.
    enum SupportedLanguages: String, StringCaseListable {
        case
        Base,
        en // This is a workaround for a bug with StringCaseListable freaking out with single-case enums, which will (hopefully) go away in Swift 5

        var isDeveloperLanguage: Bool {
            switch self {
            case .Base,
                 .en:
                return true
            }
        }

        var bundle: Bundle {
            let bundleName: String
            switch self {
            case .en:
                bundleName = SupportedLanguages.Base.rawValue
            default:
                bundleName = rawValue
            }

            let bundlePath = Bundle.main.path(forResource: bundleName, ofType: ".lproj")!
            return Bundle(path: bundlePath)!
        }

        func localizedString(for key: String) -> String {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
    }

    func testValuesExistForAllLocalizedStringKeys() {
        LocalizedKey.allCases.forEach { key in
            SupportedLanguages.allCases.forEach { language in
                let value = language.localizedString(for: key.rawValue)
                XCTAssertNotEqual(value, key.rawValue, "\(key.rawValue) does not have a value in the \(language.rawValue) Localizable.strings! Make sure you either revert the change to Localizable.strings or regenerate the LocalizableStrings.swift file using Marathon - see README for instructions.")
            }
        }
    }

    func testValuesExistForLocalizedPluralKeys() {
        LocalizedPluralKey.allCases.forEach { key in
            SupportedLanguages.allCases.forEach { language in
                let format = language.localizedString(for: key.rawValue)
                let zeroValue = String.localizedStringWithFormat(format, 0)
                XCTAssertNotEqual(zeroValue, key.rawValue, "\(key.rawValue) does not have a value in the \(language.rawValue) Localizable.stringsdict for 0! Make sure you either revert the change to Localizable.stringsdict or regenerate the LocalizedPluralStrings.swift file using Marathon - see README for instructions.")

                let oneValue = String.localizedStringWithFormat(format, 1)
                XCTAssertNotEqual(oneValue, key.rawValue, "\(key.rawValue) does not have a value in the \(language.rawValue) Localizable.stringsdict for 1! Make sure you revert the change to Localizable.stringsdict or regenerate the LocalizedPluralStrings.swift file using Marathon - see README for instructions.")

                if language.isDeveloperLanguage {
                    // Given English pluralization rules, the values for zero and one should not be the same.
                    XCTAssertNotEqual(zeroValue, oneValue, "Zero value and one value are both \(zeroValue) in \(language.rawValue) for \(key.rawValue)! This should not be the case for english - validate that you've added translations properly per plurlaization to Localizable.stringsdict.")
                }
            }
        }
    }

    func testImagesExistForAssetCatalogItems() {
        AssetCatalogItem.allCases.forEach { item in
            XCTAssertNotNil(UIImage(named: item.rawValue), "No image for asset catalog item named \"\(item.rawValue)\". Make sure you either revert the change to the Asset Catalog or regenerate the AssetCatalog.swift file using Marathon - see README for instructions.")
        }
    }
}
