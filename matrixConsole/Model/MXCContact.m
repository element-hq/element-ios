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

#import "MXCContact.h"

#import "MXCEmail.h"
#import "MXCPhoneNumber.h"

// warn when a contact has a new matrix identifier
// the contactID is provided in parameter
NSString *const kMXCContactMatrixIdentifierUpdateNotification = @"kMXCContactMatrixIdentifierUpdateNotification";

// warn when the contact thumbnail is updated
// the contactID is provided in parameter
NSString *const kMXCContactThumbnailUpdateNotification = @"kMXCContactThumbnailUpdateNotification";

@interface MXCContact() {
    UIImage* contactBookThumbnail;
    UIImage* matrixThumbnail;
    
    // used when the contact is not defined in the contacts book
    MXCContactField * dummyField;
}
@end

@implementation MXCContact

- (id) initWithABRecord:(ABRecordRef)record {
    self = [super init];
    
    if (self) {
        // compute a contact ID
        _contactID = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(record)];

        // use the contact book display name
        _displayName = (__bridge NSString*) ABRecordCopyCompositeName(record);
        
        // avoid nil display name
        // the display name is used to sort contacts
        if (!_displayName) {
            _displayName = @"";
        }
        
        dummyField = nil;
        
        // extract the phone numbers and their related label
        ABMultiValueRef multi = ABRecordCopyValue(record, kABPersonPhoneProperty);
        CFIndex        nCount = ABMultiValueGetCount(multi);
        NSMutableArray* pns = [[NSMutableArray alloc] initWithCapacity:nCount];
        
        for (int i = 0; i < nCount; i++) {
            CFTypeRef phoneRef = ABMultiValueCopyValueAtIndex(multi, i);
            NSString *phoneVal = (__bridge NSString*)phoneRef;
            
            // sanity check
            if (0 != [phoneVal length]) {
                CFStringRef lblRef = ABMultiValueCopyLabelAtIndex(multi, i);
                CFStringRef localizedLblRef = nil;
                NSString *lbl =  @"";
                
                if (lblRef != nil) {
                    localizedLblRef = ABAddressBookCopyLocalizedLabel(lblRef);
                    if (localizedLblRef) {
                        lbl = (__bridge NSString*)localizedLblRef;
                    } else  {
                        lbl = (__bridge NSString*)lblRef;
                    }
                } else {
                    localizedLblRef = ABAddressBookCopyLocalizedLabel(kABOtherLabel);
                    if (localizedLblRef) {
                        lbl = (__bridge NSString*)localizedLblRef;
                    }
                }
        
                [pns addObject:[[MXCPhoneNumber alloc] initWithTextNumber:phoneVal type:lbl contactID:_contactID matrixID:nil]];
                
                if (lblRef)  {
                    CFRelease(lblRef);
                }
                if (localizedLblRef) {
                    CFRelease(localizedLblRef);
                }
            }
            
            // release meory
            if (phoneRef) {
                CFRelease(phoneRef);
            }
        }
        
        CFRelease(multi);
        _phoneNumbers = pns;
        
        // extract the emails
        multi = ABRecordCopyValue(record, kABPersonEmailProperty);
        nCount = ABMultiValueGetCount(multi);
        
        NSMutableArray *emails = [[NSMutableArray alloc] initWithCapacity:nCount];
        
        for (int i = 0; i < nCount; i++) {
            CFTypeRef emailValRef = ABMultiValueCopyValueAtIndex(multi, i);
            NSString *emailVal = (__bridge NSString*)emailValRef;
            
            // sanity check
            if ((nil != emailVal) && (0 != [emailVal length])) {
                CFStringRef lblRef = ABMultiValueCopyLabelAtIndex(multi, i);
                CFStringRef localizedLblRef = nil;
                NSString *lbl =  @"";
                
                if (lblRef != nil) {
                    localizedLblRef = ABAddressBookCopyLocalizedLabel(lblRef);
                    
                    if (localizedLblRef) {
                        lbl = (__bridge NSString*)localizedLblRef;
                    }
                    else  {
                        lbl = (__bridge NSString*)lblRef;
                    }
                } else {
                    localizedLblRef = ABAddressBookCopyLocalizedLabel(kABOtherLabel);
                    if (localizedLblRef) {
                        lbl = (__bridge NSString*)localizedLblRef;
                    }
                }
                
                [emails addObject: [[MXCEmail alloc] initWithEmailAddress:emailVal type:lbl contactID:_contactID matrixID:nil]];
                
                if (lblRef) {
                    CFRelease(lblRef);
                }
                
                if (localizedLblRef) {
                    CFRelease(localizedLblRef);
                }
            }
            
            if (emailValRef)  {
                CFRelease(emailValRef);
            }
        }
        
        CFRelease(multi);

        _emailAddresses = emails;
        
        // thumbnail/picture
        // check whether the contact has a picture
        if (ABPersonHasImageData(record))
        {
            CFDataRef dataRef;
            
            dataRef = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
            if (dataRef)
            {
                contactBookThumbnail = [UIImage imageWithData:(__bridge NSData*)dataRef];
                CFRelease(dataRef);
            }
        }
    }
    return self;
}

// create a contact with the dedicated info
- (id)initWithDisplayName:(NSString*)aDisplayName matrixID:(NSString*)matrixID
{
    self = [super init];
    
    if (self) {
        _contactID = [[NSUUID UUID] UUIDString];
        
        // used when the contact is not defined in the contacts book
        dummyField = [[MXCContactField alloc] initWithContactID:_contactID matrixID:matrixID];
        
        // _displayName must not be nil
        // it is used to sort the contacts
        if (aDisplayName) {
            _displayName = aDisplayName;
        } else {
            _displayName = @"";
        }
    }
    
    return self;
}

- (BOOL) isMatrixContact {
    return (nil != dummyField);
}

- (NSArray*) matrixIdentifiers {
    NSMutableArray* identifiers = [[NSMutableArray alloc] init];
    
    if (dummyField) {
        [identifiers addObject:dummyField.matrixID];
    }
    
    for(MXCEmail* email in _emailAddresses) {
        if (email.matrixID && ([identifiers indexOfObject:email.matrixID] == NSNotFound)) {
            [identifiers addObject:email.matrixID];
        }
    }
    
    for(MXCPhoneNumber* pn in _phoneNumbers) {
        if (pn.matrixID && ([identifiers indexOfObject:pn.matrixID] == NSNotFound)) {
            [identifiers addObject:pn.matrixID];
        }
    }

    return identifiers;
}

- (void)setDisplayName:(NSString *)displayName {
    // a display name must not be emptied
    // it is used to sort the contacts
    if (displayName.length == 0) {
        _displayName = _contactID;
    } else {
        _displayName = displayName;
    }
}

// return thumbnail with a prefered size
// if the thumbnail is already loaded, this method returns this one
// if the thumbnail must trigger a server request, the expected size will be size
// self.thumbnail triggered a request with a 256 X 256 pixels
- (UIImage*)thumbnailWithPreferedSize:(CGSize)size {
    // already found a matrix thumbnail
    if (matrixThumbnail) {
        return matrixThumbnail;
    } else {
        //
        MXCContactField* firstField = dummyField;
        
        if (firstField) {
            if (firstField.avatarImage) {
                matrixThumbnail = firstField.avatarImage;
                return matrixThumbnail;
            }
        }
        
        // try to replace the thumbnail by the matrix one
        if (_emailAddresses.count > 0) {
            // list the linked email
            // search if one email field has a dedicated thumbnail
            for(MXCEmail* email in _emailAddresses) {
                if (email.avatarImage) {
                    matrixThumbnail = email.avatarImage;
                    return matrixThumbnail;
                } else if (!firstField) {
                    firstField = email;
                }
            }
        }
        
        // if no thumbnail has been found
        // try to load the first field one
        if (firstField) {
            // should be retrieved by the cell info
            [firstField loadAvatarWithSize:size];
        }
        
        return contactBookThumbnail;
    }
}

- (UIImage*)thumbnail {
    return [self thumbnailWithPreferedSize:CGSizeMake(256, 256)];
}

@end
