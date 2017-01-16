#import <Contacts/Contacts.h>
#import <Foundation/Foundation.h>
#import <SignalServiceKit/ContactsManagerProtocol.h>
#import <SignalServiceKit/PhoneNumber.h>
#import "CollapsingFutures.h"
#import "Contact.h"

/**
 Get Signal or Token contacts. 
 */

@class TokenContact;

@interface ContactsManager : NSObject <ContactsManagerProtocol>

+ (BOOL)name:(NSString * _Nonnull)nameString matchesQuery:(NSString * _Nonnull)queryString;

- (NSString * _Nonnull)displayNameForPhoneIdentifier:(NSString * _Nullable)phoneNumber;

- (NSArray<Contact *> * _Nonnull)signalContacts;

- (NSArray<TokenContact *> * _Nonnull)tokenContacts;

- (UIImage * _Nullable)imageForPhoneIdentifier:(NSString * _Nullable)phoneNumber;

@end
