//
//  GTContactsPicker.m
//  GTContactsKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Gianluca Tranchedone (@gtranchedone)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GTContactsPicker.h"
#import "GTPerson.h"

@interface GTContactsPicker ()

@property (nonatomic, copy) NSError *addressBookError;

@end

@implementation GTContactsPicker

- (void)dealloc
{
    CFRelease(self.addressBook);
}

#pragma mark - Public APIs -
- (instancetype)initWithPickerStyle:(GTContactsPickerStyle)pickerStyle
{
    self = [super init];
    if (self) {
        _pickerStyle = pickerStyle;
    }
    return self;
}

- (ABAuthorizationStatus)addressBookAuthorizationStatus
{
    return ABAddressBookGetAuthorizationStatus();
}

- (void)fetchContactsWithCompletionBlock:(void (^)(NSArray *contacts, NSError *error))completionBlock
{
    NSError *fetchError = self.addressBookError;
    if (!fetchError) {
        ABAuthorizationStatus status = [self addressBookAuthorizationStatus];
        switch (status) {
            case kABAuthorizationStatusNotDetermined:
                [self requestAddressBookAccessAuthorizationWithCompletion:completionBlock];
                break;

            case kABAuthorizationStatusAuthorized:
                [self fetchAllContactsWithCompletionBlock:completionBlock];
                break;

            default:
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Unauthorized to use Contacts information"};
                fetchError = [NSError errorWithDomain:GTContactsPickerErrorDomain code:400 userInfo:userInfo];
                completionBlock(nil, fetchError);
            }
                break;
        }
    }
    else if (completionBlock) {
        completionBlock(nil, fetchError);
    }
}

- (void)requestAddressBookAccessAuthorizationWithCompletion:(void (^)(NSArray *, NSError *))completionBlock
{
    __weak typeof(self) weakSelf = self;
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        if (!error) {
            [weakSelf fetchContactsWithCompletionBlock:completionBlock];
        }
        else if (completionBlock) {
            completionBlock(nil, (__bridge NSError *)error);
        }
    });
}

#pragma mark - Private APIs -

- (void)fetchAllContactsWithCompletionBlock:(void (^)(NSArray *, NSError *))completionBlock
{
    if (completionBlock) {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(self.addressBook,
                                                                                      NULL,
                                                                                      ABPersonGetSortOrdering());
        NSArray *allPeople = (__bridge NSArray *)people;
        NSMutableArray *formattedPeople = [NSMutableArray arrayWithCapacity:allPeople.count];
        
        for (id object in allPeople) {
            GTPerson *person = [[GTPerson alloc] init];
            ABRecordRef record = (__bridge ABRecordRef)(object);
            if (ABPersonHasImageData(record)) {
                CFDataRef data = ABPersonCopyImageDataWithFormat(record,kABPersonImageFormatThumbnail);
                person.profileImage = [UIImage imageWithData:(__bridge NSData *)data];
                CFRelease(data);
            }
            
            id firstName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonFirstNameProperty));
            person.firstName = firstName;
            
            id lastName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonLastNameProperty));
            person.lastName = lastName;

            if (!firstName && !lastName) {
                firstName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonOrganizationProperty));
                person.firstName = firstName;
            }
            
            if (self.pickerStyle == GTContactsPickerStyleSingularEmail) {
                [formattedPeople addObjectsFromArray:[self sinGularEmailAddressesForRecord:record
                                                                                  ofPerson:person]];
            }
            else {
                person.emailAddresses = [self emailAddressesForRecord:record];
                person.phoneNumbers = [self phoneNumbersForRecord:record];
                
                [formattedPeople addObject:person];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionBlock(formattedPeople, nil);
        }];
    }
}

- (NSArray *)sinGularEmailAddressesForRecord:(ABRecordRef)record ofPerson:(GTPerson*)personCurrent{
    
    ABMultiValueRef emails = ABRecordCopyValue(record, kABPersonEmailProperty);
    CFIndex emailsCount = ABMultiValueGetCount(emails);
    NSMutableArray *personSingularEmail = [NSMutableArray arrayWithCapacity:(NSUInteger)emailsCount];
    
    for (CFIndex i = 0; i < emailsCount; i++) {
        GTPerson *person = [[GTPerson alloc] init];
        person.firstName = personCurrent.firstName;
        person.lastName = personCurrent.lastName;
        person.phoneNumbers = [self phoneNumbersForRecord:record];
        
        NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
        
        NSMutableArray *emailAddresses = [NSMutableArray arrayWithCapacity:1];
        [emailAddresses addObject:email];
        
        person.emailAddresses = emailAddresses;
        
        [personSingularEmail addObject:person];
    }
    
    CFRelease(emails);
    
    return [personSingularEmail copy];
}

- (NSArray *)emailAddressesForRecord:(ABRecordRef)record
{
    ABMultiValueRef emails = ABRecordCopyValue(record, kABPersonEmailProperty);
    CFIndex emailsCount = ABMultiValueGetCount(emails);
    NSMutableArray *emailAddresses = [NSMutableArray arrayWithCapacity:(NSUInteger)emailsCount];
    
    for (CFIndex i = 0; i < emailsCount; i++) {
        NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
        [emailAddresses addObject:email];
    }
    
    CFRelease(emails);
    
    return [emailAddresses copy];
}

- (NSArray *)phoneNumbersForRecord:(ABRecordRef)record
{
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
    CFIndex numbersCount = ABMultiValueGetCount(phoneNumbers);
    NSMutableArray *numbers = [NSMutableArray arrayWithCapacity:(NSUInteger)numbersCount];
    
    for (CFIndex i = 0; i < numbersCount; i++) {
        NSString *number = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
        [numbers addObject:number];
    }
    
    CFRelease(phoneNumbers);
    
    return [numbers copy];
}

#pragma mark - Setters and Getters -

- (ABAddressBookRef)addressBook
{
    if (!_addressBook) {
        CFErrorRef error = NULL;
        CFDictionaryRef options = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(options, &error);
        if (error) {
            self.addressBookError = (__bridge NSError *)error;
        }
    }
    return _addressBook;
}

@end

NSString * const GTContactsPickerErrorDomain = @"com.gtranchedone.GTContactsPicker";
