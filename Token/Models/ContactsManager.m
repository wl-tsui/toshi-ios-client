#import <UIKit/UIKit.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/SignalRecipient.h>

#import "ContactsManager.h"

#import "Token-Swift.h"

@interface ContactsManager ()
@property (nonnull, nonatomic, readonly) Yap *yap;
@end

@implementation ContactsManager

- (Yap *)yap {
    return [Yap sharedInstance];
}

+ (BOOL)name:(nonnull NSString *)nameString matchesQuery:(nonnull NSString *)queryString {
    return YES;
}

- (nonnull NSString *)displayNameForPhoneIdentifier:(nullable NSString *)phoneNumber {
    for (SignalAccount *account in self.signalAccounts) {
        Contact *contact = account.contact;
        if ([contact.userTextPhoneNumbers.firstObject isEqualToString:phoneNumber]) {
            return contact.firstName;
        }
    }

    return @"";
}

- (NSArray<TokenUser *> *)tokenContacts {
    NSMutableArray <TokenUser *> *contacts = [NSMutableArray array];

    for (NSData *contactData in [Yap.sharedInstance retrieveObjectsIn:TokenUser.storedContactKey]) {
        NSDictionary<NSString *, id> *json = [NSJSONSerialization JSONObjectWithData:contactData options:0 error:0];
        TokenUser *tokenContact = [[TokenUser alloc] initWithJson:json shouldSave:NO];

        [contacts addObject:tokenContact];
    }

    return contacts.copy;
}

- (nullable TokenUser *)tokenContactForAddress:(nullable NSString *)address {
    if (!address) { return nil; }

    for (TokenUser *contact in self.tokenContacts) {
        if ([contact.address isEqualToString:address]) {
            return contact;
        }
    }

    return nil;
}

- (NSArray<SignalAccount *> *)signalAccounts {
    NSMutableDictionary<NSString *, SignalAccount *> *signalAccountMap = [NSMutableDictionary dictionary];
    NSMutableArray<SignalAccount *> *signalAccounts = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray<SignalRecipient *> *> *contactIdToSignalRecipientsMap = [NSMutableDictionary dictionary];
    NSMutableArray<Contact *> *contacts = [NSMutableArray array];

    [[TSStorageManager sharedManager].dbConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        for (TokenUser *tokenContact in self.tokenContacts) {
            Contact *contact = [[Contact alloc] initWithContactWithFirstName:tokenContact.username andLastName:tokenContact.name andUserTextPhoneNumbers:@[tokenContact.address] andImage:nil andContactID:(int)tokenContact.hash];

            [contacts addObject:contact];

            NSArray<SignalRecipient *> *recipients = [contact signalRecipientsWithTransaction:transaction];
            contactIdToSignalRecipientsMap[contact.uniqueId] = recipients;
        }
    }];

    for (Contact *contact in contacts) {
        NSArray<SignalRecipient *> *signalRecipients = contactIdToSignalRecipientsMap[contact.uniqueId];
        for (SignalRecipient *signalRecipient in [signalRecipients sortedArrayUsingSelector:@selector(compare:)]) {
            SignalAccount *signalAccount = [[SignalAccount alloc] initWithSignalRecipient:signalRecipient];
            signalAccount.contact = contact;
            if (signalRecipients.count > 1) {
                @throw NSInvalidArgumentException;

            }

            if (signalAccountMap[signalAccount.recipientId]) {
                NSLog(@"Ignoring duplicate contact: %@, %@", signalAccount.recipientId, contact.fullName);
                continue;
            }

            signalAccountMap[signalAccount.recipientId] = signalAccount;
            [signalAccounts addObject:signalAccount];
        }
    }


    return signalAccounts;
}

- (nullable UIImage *)imageForPhoneIdentifier:(nullable NSString *)phoneNumber {
    TokenUser *contact = [self tokenContactForAddress:phoneNumber];

    return contact.avatar;
}

@end
