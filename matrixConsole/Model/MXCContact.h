/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

// warn when a contact has a new matrix identifier
// the contactID is provided in parameter
extern NSString *const kMXCContactMatrixIdentifierUpdateNotification;
// warn when the contact thumbnail is updated
// the contactID is provided in parameter
extern NSString *const kMXCContactThumbnailUpdateNotification;

@interface MXCContact : NSObject<NSCoding>

// unique identifier
@property (nonatomic, readonly) NSString * contactID;
// display name
@property (nonatomic, readwrite) NSString *displayName;
// contact thumbnail
@property (nonatomic, copy, readonly) UIImage *thumbnail;
// YES if the contact does not exist in the contacts book
// the contact has been created from a MXUser
@property (nonatomic, readonly) BOOL isMatrixContact;
// array of MXCPhoneNumber
@property (nonatomic, readonly) NSArray *phoneNumbers;
// array of MXCEmail
@property (nonatomic, readonly) NSArray *emailAddresses;
// array of matrix identifiers
@property (nonatomic, readonly) NSArray* matrixIdentifiers;

// return the contact ID from native phonebook record
+ (NSString*)contactID:(ABRecordRef)record;

// create a contact from a local contact
- (id)initWithABRecord:(ABRecordRef)record;

// create a contact with the dedicated info
- (id)initWithDisplayName:(NSString*)displayName matrixID:(NSString*)matrixID;

// return thumbnail with a prefered size
// if the thumbnail is already loaded, this method returns this one
// if the thumbnail must trigger a server request, the expected size will be size
// self.thumbnail triggered a request with a 256 X 256 pixels
- (UIImage*)thumbnailWithPreferedSize:(CGSize)size;

// check if the patterns can match with this contact
- (BOOL) matchedWithPatterns:(NSArray*)patterns;

// internationalize the contact phonenumbers
- (void)internationalizePhonenumbers:(NSString*)countryCode;

@end