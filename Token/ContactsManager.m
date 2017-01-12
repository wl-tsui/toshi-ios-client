#import "ContactsManager.h"
#import <UIKit/UIKit.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/SignalRecipient.h>

@interface ContactsManager ()

@end

@implementation ContactsManager

+ (BOOL)name:(NSString * _Nonnull)nameString matchesQuery:(NSString * _Nonnull)queryString {
    return YES;
}

- (NSArray <NSDictionary<NSString *, id> *> *)hardcodedContacts {
    return @[
             @{@"firstName": @"Igor", @"lastName": @"Simulator", @"address": @"0xee216f51a2f25f437defbc8973c9eddc56b07ce1", @"image": @"igorSim"},
             @{@"firstName": @"Igor", @"lastName": @"Device", @"address": @"0x27d3a723fce45a308788dca08450caaaf4ceb79b", @"image": @"igorPhone"},
             @{@"firstName": @"Colin", @"lastName": @"Android", @"address": @"0x98484b79ea9aa8cdd747ad669295c80ac933cc25", @"image": @"colin"},
            ];
}

- (NSString * _Nonnull)displayNameForPhoneIdentifier:(NSString * _Nullable)phoneNumber {
    for (Contact *contact in self.signalContacts) {
        if ([contact.userTextPhoneNumbers.firstObject isEqualToString:phoneNumber]) {
            return contact.fullName;
        }
    }

    return @"Error matching address to contact";
}

- (NSArray<Contact *> * _Nonnull)signalContacts {

    __block NSMutableArray <NSString *> *contactIDs = [[NSMutableArray alloc] init];

    [[TSStorageManager sharedManager].dbConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
         NSArray *allRecipientKeys = [transaction allKeysInCollection:[SignalRecipient collection]];

        [contactIDs addObjectsFromArray:allRecipientKeys];
     }];


    __block NSMutableArray <Contact *> *contacts = [[NSMutableArray alloc] init];
    for (NSDictionary *contactDict in self.hardcodedContacts) {
        for (NSString *contactID in contactIDs) {
            if ([contactDict[@"address"] isEqualToString:contactID]) {

                UIImage *image = [UIImage imageNamed:contactDict[@"image"]];
                Contact *contact = [[Contact alloc] initWithContactWithFirstName:contactDict[@"firstName"] andLastName:contactDict[@"lastName"] andUserTextPhoneNumbers:@[contactID] andImage:image andContactID:(int)contactID.hash];
                [contacts addObject:contact];

                break;
            }
        }
    }

    return contacts.copy;
}

- (UIImage * _Nullable)imageForPhoneIdentifier:(NSString * _Nullable)phoneNumber {
    for (Contact *contact in self.signalContacts) {
        if ([contact.userTextPhoneNumbers.firstObject isEqualToString:phoneNumber]) {
            return contact.image;
        }
    }

    return nil;
}

@end
