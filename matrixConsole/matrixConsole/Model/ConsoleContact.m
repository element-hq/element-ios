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

@implementation ConsoleContact
@synthesize displayName, phoneNumbers, emailAddresses, thumbnail;

- (id) initWithABRecord:(ABRecordRef)record {
    
    self = [super init];
    
    if (self) {
        
        self.displayName = (__bridge NSString*) ABRecordCopyCompositeName(record);
        
        // avoid nil display name
        // the display name is used to sort contacts
        if (!self.displayName) {
            self.displayName = @"";
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
        self.phoneNumbers = pns;
        
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
                
                ConsoleEmail* email = [[ConsoleEmail alloc] init];
                email.type = lbl;
                email.emailAddress = emailVal;
                
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

        self.emailAddresses = emails;
        
        // thumbnail/picture
        // check whether the contact has a picture
        if (ABPersonHasImageData(record))
        {
            CFDataRef dataRef;
            
            dataRef = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
            if (dataRef)
            {
                self.thumbnail = [UIImage imageWithData:(__bridge NSData*)dataRef];
                CFRelease(dataRef);
            }
        }
    }
    return self;
}

- (NSArray*) matrixIdentifiers {
    NSMutableArray* identifiers = [[NSMutableArray alloc] init];
    
    for(ConsolePhoneNumber* pn in self.phoneNumbers) {
        if (pn.isMatrixIdentifier) {
            [identifiers addObject:pn.textNumber];
        }
    }
    
    for(ConsoleEmail* email in self.emailAddresses) {
        if (email.isMatrixIdentifier) {
            [identifiers addObject:email.emailAddress];
        }
    }

    return identifiers;
}

@end
