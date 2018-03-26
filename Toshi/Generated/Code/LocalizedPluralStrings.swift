// This file is machine-generated. DO NOT EDIT IT BY HAND - your edits will get overwritten.

import Foundation

enum LocalizedPluralKey: String, StringCaseListable {
    case
    group_participants_header_title,
    message_requests_description,
    passphrase_sign_in_button_placeholder,
    passphrase_sign_in_error,
    ratings_count

    func currentValue(for count: Int) -> String {
        let format = NSLocalizedString(rawValue, comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}

enum LocalizedPlural {
    
    /// Values in en:
    /// - one: "%d Participant"
    /// - other: "%d Participants"
    ///
    /// - Parameter count: The count of items to show a plural for.
    /// - Returns: The localized string appropriate to the given count.
    static func group_participants_header_title(for count: Int) -> String {
        return LocalizedPluralKey.group_participants_header_title.currentValue(for: count)
    }
    
    /// Values in en:
    /// - one: "%d person wants to start a chat"
    /// - other: "%d people want to start a chat"
    ///
    /// - Parameter count: The count of items to show a plural for.
    /// - Returns: The localized string appropriate to the given count.
    static func message_requests_description(for count: Int) -> String {
        return LocalizedPluralKey.message_requests_description.currentValue(for: count)
    }
    
    /// Values in en:
    /// - one: "%d more word"
    /// - other: "%d more words"
    ///
    /// - Parameter count: The count of items to show a plural for.
    /// - Returns: The localized string appropriate to the given count.
    static func passphrase_sign_in_button_placeholder(for count: Int) -> String {
        return LocalizedPluralKey.passphrase_sign_in_button_placeholder.currentValue(for: count)
    }
    
    /// Values in en:
    /// - one: "%d word you typed does not exist in passphrases."
    /// - other: "%d of the words you typed do not exist in passphrases."
    ///
    /// - Parameter count: The count of items to show a plural for.
    /// - Returns: The localized string appropriate to the given count.
    static func passphrase_sign_in_error(for count: Int) -> String {
        return LocalizedPluralKey.passphrase_sign_in_error.currentValue(for: count)
    }
    
    /// Values in en:
    /// - one: "%d rating"
    /// - other: "%d ratings"
    ///
    /// - Parameter count: The count of items to show a plural for.
    /// - Returns: The localized string appropriate to the given count.
    static func ratings_count(for count: Int) -> String {
        return LocalizedPluralKey.ratings_count.currentValue(for: count)
    }
}
