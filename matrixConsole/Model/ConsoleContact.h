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
extern NSString *const kConsoleContactMatrixIdentifierUpdateNotification;
// warn when the contact thumbnail is updated
// the contactID is provided in parameter
extern NSString *const kConsoleContactThumbnailUpdateNotification;

@interface ConsoleContact : NSObject

// unique identifier
@property (nonatomic, readonly) NSString * contactID;
// display name
@property (nonatomic, readonly) NSString *displayName;
// contact thumbnail
@property (nonatomic, copy, readonly) UIImage *thumbnail;
// array of ConsolePhoneNumber
@property (nonatomic, readonly) NSArray *phoneNumbers;
// array of ConsoleEmail
@property (nonatomic, readonly) NSArray *emailAddresses;
// array of matrix identifiers
@property (nonatomic, readonly) NSArray* matrixIdentifiers;

- (id)initWithABRecord:(ABRecordRef)record;

// return thumbnail with a prefered size
// if the thumbnail is already loaded, this method returns this one
// if the thumbnail must trigger a server request, the expected size will be size
// self.thumbnail triggered a request with a 256 X 256 pixels
- (UIImage*)thumbnailWithPreferedSize:(CGSize)size;

// check if there is any matrix identifier updates
- (void)checkMatrixIdentifiers;


@end