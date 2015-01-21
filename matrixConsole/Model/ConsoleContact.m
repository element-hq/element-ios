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

#import "ConsoleContact.h"

#import "ConsoleEmail.h"
#import "ConsolePhoneNumber.h"

// warn when a contact has a new matrix identifier
// the contactID is provided in parameter
NSString *const kConsoleContactMatrixIdentifierUpdateNotification = @"kConsoleContactMatrixIdentifierUpdateNotification";

// warn when the contact thumbnail is updated
// the contactID is provided in parameter
NSString *const kConsoleContactThumbnailUpdateNotification = @"kConsoleContactThumbnailUpdateNotification";

@interface ConsoleContact() {
    UIImage* contactBookThumbnail;
    UIImage* matrixThumbnail;
}
@end

@implementation ConsoleContact

- (id) initWithABRecord:(ABRecordRef)record {
    self = [super init];
    
    if (self) {
        // compute a contact ID
        _contactID = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(record)];

        // use the contact book display name
        _displayName = (__bridge NSString*) ABRecordCopyCompositeName(record);
        
        // avoid nil display name
        // the display name is used to sort contacts
        if (!self.displayName) {
            _displayName = @"";
        }
        
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
        
                [pns addObject:[[ConsolePhoneNumber alloc] initWithTextNumber:phoneVal andType:lbl within:self.contactID]];
                
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
                
                [emails addObject: [[ConsoleEmail alloc] initWithEmailAddress:emailVal andType:lbl within:self.contactID]];
                
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            [self checkMatrixIdentifiers];
        });
    }
    return self;
}

- (NSArray*) matrixIdentifiers {
    NSMutableArray* identifiers = [[NSMutableArray alloc] init];
    
    for(ConsoleEmail* email in self.emailAddresses) {
        if (email.matrixUserID && ([identifiers indexOfObject:email.matrixUserID] == NSNotFound)) {
            [identifiers addObject:email.matrixUserID];
        }
    }

    return identifiers;
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
        
        // try to replace the thumbnail by the matrix one
        if (self.emailAddresses.count > 0) {
            //
            ConsoleEmail* firstEmail = nil;
            
            // list the linked email
            // search if one email field has a dedicated thumbnail
            for(ConsoleEmail* email in self.emailAddresses) {
                if (email.avatarImage) {
                    matrixThumbnail = email.avatarImage;
                    return matrixThumbnail;
                } else if (!firstEmail) {
                    firstEmail = email;
                }
            }
            
            // if no thumbnail has been found
            // try to load the first email one
            if (firstEmail) {
                // should be retrieved by the cell info
                [firstEmail loadAvatarWithSize:size];
            }
        }
        
        return contactBookThumbnail;
    }
}

- (UIImage*)thumbnail {
    return [self thumbnailWithPreferedSize:CGSizeMake(256, 256)];
}

- (void)checkMatrixIdentifiers {
    for(ConsoleEmail* email in self.emailAddresses) {
        [email getMatrixID];
    }
}

@end
