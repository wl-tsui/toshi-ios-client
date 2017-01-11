#import "ContactsManager.h"

@interface ContactsManager ()

@end

@implementation ContactsManager

+ (BOOL)name:(NSString * _Nonnull)nameString matchesQuery:(NSString * _Nonnull)queryString {
    return YES;
}

- (NSString * _Nonnull)displayNameForPhoneIdentifier:(NSString * _Nullable)phoneNumber {
    return self.signalContacts.firstObject.firstName;
}

- (NSArray<Contact *> * _Nonnull)signalContacts {
    Contact *contact = [[Contact alloc] initWithContactWithFirstName:@"Igor" andLastName:@"Simulator" andUserTextPhoneNumbers:@[@"0x86edf5ca7de8825d67a1cc0c50b5dd3739a1bb0d"] andImage:nil andContactID:12301];

    return @[contact];
}

- (UIImage * _Nullable)imageForPhoneIdentifier:(NSString * _Nullable)phoneNumber {
    return nil;
}

@end
