/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "MXKCellData.h"

#import "MXKEmail.h"
#import "MXKPhoneNumber.h"

/**
 Posted when the contact thumbnail is updated.
 The notification object is a contact Id.
 */
extern NSString *const kMXKContactThumbnailUpdateNotification;

extern NSString *const kMXKContactLocalContactPrefixId;
extern NSString *const kMXKContactMatrixContactPrefixId;
extern NSString *const kMXKContactDefaultContactPrefixId;

@interface MXKContact : MXKCellData <NSCoding>

/**
 The unique identifier
 */
@property (nonatomic, readonly) NSString * contactID;

/**
 The display name
 */
@property (nonatomic, readwrite) NSString *displayName;

/**
 The sorting display name built by trimming the symbols [_!~`@#$%^&*-+();:={}[],.<>?\/"'] from the display name.
 */
@property (nonatomic) NSString* sortingDisplayName;

/**
 The contact thumbnail. Default size: 256 X 256 pixels
 */
@property (nonatomic, copy, readonly) UIImage *thumbnail;

/**
 YES if the contact does not exist in the contacts book
 the contact has been created from a MXUser or MXRoomThirdPartyInvite
 */
@property (nonatomic) BOOL isMatrixContact;

/**
 YES if the contact is coming from MXRoomThirdPartyInvite event (NO by default).
 */
@property (nonatomic) BOOL isThirdPartyInvite;

/**
 The array of MXKPhoneNumber
 */
@property (nonatomic, readonly) NSArray *phoneNumbers;

/**
 The array of MXKEmail
 */
@property (nonatomic, readonly) NSArray *emailAddresses;

/**
 The array of matrix identifiers
 */
@property (nonatomic, readonly) NSArray* matrixIdentifiers;

/**
 The matrix avatar url used (if any) to build the current thumbnail, nil by default.
 */
@property (nonatomic, readonly) NSString* matrixAvatarURL;

/**
 Reset the current thumbnail if it is retrieved from a matrix url. May be used in case of the matrix avatar url change.
 A new thumbnail will be automatically restored from the contact data.
 */
- (void)resetMatrixThumbnail;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
/**
 The contact ID from native phonebook record
 */
+ (NSString*)contactID:(ABRecordRef)record;

/**
 Create a local contact from a device contact
 
 @param record device contact id
 @return MXKContact instance
 */
- (id)initLocalContactWithABRecord:(ABRecordRef)record;
#pragma clang diagnostic pop

/**
 Create a matrix contact with the dedicated info
 
 @param displayName the contact display name
 @param matrixID the contact matrix id
 @return MXKContact instance
 */
- (id)initMatrixContactWithDisplayName:(NSString*)displayName andMatrixID:(NSString*)matrixID;

/**
 Create a matrix contact with the dedicated info

 @param displayName the contact display name
 @param matrixID the contact matrix id
 @param matrixAvatarURL the matrix avatar url
 @return MXKContact instance
 */
- (id)initMatrixContactWithDisplayName:(NSString*)displayName matrixID:(NSString*)matrixID andMatrixAvatarURL:(NSString*)matrixAvatarURL;

/**
 Create a contact with the dedicated info
 
 @param displayName the contact display name
 @param emails an array of emails
 @param phones an array of phone numbers
 @param thumbnail  the contact thumbnail
 @return MXKContact instance
 */
- (id)initContactWithDisplayName:(NSString*)displayName
                          emails:(NSArray<MXKEmail*> *)emails
                    phoneNumbers:(NSArray<MXKPhoneNumber*> *)phones
                    andThumbnail:(UIImage *)thumbnail;

/**
 The contact thumbnail with a prefered size.
 
 If the thumbnail is already loaded, this method returns this one by ignoring prefered size.
 The prefered size is used only if a server request is required.
 
 @return thumbnail with a prefered size
 */
- (UIImage*)thumbnailWithPreferedSize:(CGSize)size;

/**
 Tell whether a component of the contact's displayName, or one of his matrix id/email has the provided prefix.
 
 @param prefix a non empty string.
 @return YES when at least one matrix id, email or a component of the display name has this prefix.
 */
- (BOOL)hasPrefix:(NSString*)prefix;

/**
 Check if the patterns can match with this contact
 */
- (BOOL)matchedWithPatterns:(NSArray*)patterns;

/**
 The default ISO 3166-1 country code used to internationalize the contact phone numbers.
 */
@property (nonatomic) NSString *defaultCountryCode;

@end
