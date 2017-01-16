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

+ (BOOL)name:(NSString * _Nonnull)nameString matchesQuery:(NSString * _Nonnull)queryString {
    return YES;
}

- (NSString * _Nonnull)displayNameForPhoneIdentifier:(NSString * _Nullable)phoneNumber {
    for (Contact *contact in self.signalContacts) {
        if ([contact.userTextPhoneNumbers.firstObject isEqualToString:phoneNumber]) {
            return contact.fullName;
        }
    }

    NSLog(@"Error matching address to contact");

    return @"";
}

- (NSArray<Contact *> * _Nonnull)signalContacts {
    NSMutableArray <Contact *> *contacts = [NSMutableArray array];

    for (NSData *contactData in [self.yap retrieveObjectsIn:TokenContact.collectionKey]) {
        NSDictionary<NSString *, id> *json = [NSJSONSerialization JSONObjectWithData:contactData options:0 error:0];
        TokenContact *tokenContact = [[TokenContact alloc] initWithJson:json];

        Contact *contact = [[Contact alloc] initWithContactWithFirstName:tokenContact.username andLastName:tokenContact.name andUserTextPhoneNumbers:@[tokenContact.address] andImage:nil andContactID:(int)tokenContact.hash];

        [contacts addObject:contact];
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
