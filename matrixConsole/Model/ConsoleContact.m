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

// warn when a contact has a new matrix identifier
// the contactID is provided in parameter
NSString *const kConsoleContactMatrixIdentifierUpdateNotification = @"kConsoleContactMatrixIdentifierUpdateNotification";

#import "ConsoleEmail.h"
#import "ConsolePhoneNumber.h"

@implementation ConsoleContact
@synthesize displayName, phoneNumbers, emailAddresses, thumbnail, contactID;

- (id) initWithABRecord:(ABRecordRef)record {
    self = [super init];
    
    if (self) {

        // compute a contact ID
        self.contactID = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(record)];

        // use the contact book display name
        self.displayName = (__bridge NSString*) ABRecordCopyCompositeName(record);
        
        // avoid nil display name
        // the display name is used to sort contacts
        if (!self.displayName) {
            displayName = @"";
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
                
                ConsolePhoneNumber* pn = [[ConsolePhoneNumber alloc] init];
                pn.type = lbl;
                pn.textNumber = phoneVal;
                
                [pns addObject:pn];
                
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
        phoneNumbers = pns;
        
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
                
                ConsoleEmail* email = [[ConsoleEmail alloc] initWithEmailAddress:emailVal andType:lbl within:self.contactID];                
                [emails addObject: email];
                
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

        emailAddresses = emails;
        
        // thumbnail/picture
        // check whether the contact has a picture
        if (ABPersonHasImageData(record))
        {
            CFDataRef dataRef;
            
            dataRef = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
            if (dataRef)
            {
                thumbnail = [UIImage imageWithData:(__bridge NSData*)dataRef];
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
    
    for(ConsolePhoneNumber* pn in self.phoneNumbers) {
        if (pn.matrixUserID) {
            [identifiers addObject:pn];
        }
    }
    
    for(ConsoleEmail* email in self.emailAddresses) {
        if (email.matrixUserID) {
            [identifiers addObject:email];
        }
    }

    return identifiers;
}

- (void)checkMatrixIdentifiers {
    for(ConsolePhoneNumber* pn in self.phoneNumbers) {
        [pn getMatrixID];
    }
    
    for(ConsoleEmail* email in self.emailAddresses) {
        [email getMatrixID];
    }
}

@end
