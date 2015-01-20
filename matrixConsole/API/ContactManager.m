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

#import "ContactManager.h"

#import "ConsoleContact.h"

// warn when there is a contacts list refresh
NSString *const kContactManagerRefreshNotification = @"kContactManagerRefreshNotification";

@implementation ContactManager
@synthesize contacts;

#pragma mark Singleton Methods
static ContactManager* sharedContactManager = nil;

+ (id)sharedManager {
    @synchronized(self) {
        if(sharedContactManager == nil) 
            sharedContactManager = [[self alloc] init];
    }
    return sharedContactManager;
}

#pragma mark -

-(ContactManager *)init {
    if (self = [super init]) {
        NSString *label = [NSString stringWithFormat:@"ConsoleMatrix.%@.Contacts", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        
        processingQueue = dispatch_queue_create([label UTF8String], NULL);
        
        // put an empty array instead of nil
        contacts = [[NSMutableArray alloc] init];
        
        // check if the application is allowed to list the contacts
        ABAuthorizationStatus cbStatus = ABAddressBookGetAuthorizationStatus();
        
        // did not yet request the access
        if (cbStatus == kABAuthorizationStatusNotDetermined) {
            // request address book access
            ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
            
            if (ab) {
                ABAddressBookRequestAccessWithCompletion(ab, ^(bool granted, CFErrorRef error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self refresh];
                    });
                    
                });
                
                CFRelease(ab);
            }
        } else if (cbStatus == kABAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refresh];
            });
        }
    }
    
    return self;
}

-(void)dealloc {
}

- (void)refresh
{
    // did not yet request the access
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        // wait that the user gives the Authorization
        return;
    }
    
    dispatch_async(processingQueue, ^{
        ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
        ABRecordRef      contactRecord;
        int              index;
        
        //CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        CFMutableArrayRef people = (CFMutableArrayRef)ABAddressBookCopyArrayOfAllPeople(ab);
        
        NSMutableArray* contactsList = [[NSMutableArray alloc] init];
        
        if (nil != people) {
            int peopleCount = CFArrayGetCount(people);
            
            for (index = 0; index < peopleCount; index++) {
                contactRecord = (ABRecordRef)CFArrayGetValueAtIndex(people, index);
                [contactsList addObject:[[ConsoleContact alloc] initWithABRecord:contactRecord]];
            }
            
            CFRelease(people);
        }
                
        if (ab) {
            CFRelease(ab);
        }
        
        contacts = contactsList;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerRefreshNotification object:nil userInfo:nil];
        });
    });
}

- (SectionedContacts *)getSectionedContacts:(NSArray*)contactsList {
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    int indexOffset = 0;
    
    NSInteger index, sectionTitlesCount = [[collation sectionTitles] count];
    NSMutableArray *tmpSectionsArray = [[NSMutableArray alloc] initWithCapacity:(sectionTitlesCount)];
    
    sectionTitlesCount += indexOffset;
    
    for (index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [tmpSectionsArray addObject:array];
    }
    
    int contactsCount = 0;
    
    for (ConsoleContact *aContact in contactsList)
    {
        NSInteger section = [collation sectionForObject:aContact collationStringSelector:@selector(displayName)] + indexOffset;
        
        [[tmpSectionsArray objectAtIndex:section] addObject:aContact];
        ++contactsCount;
    }
    
    NSMutableArray *tmpSectionedContactsTitle = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    NSMutableArray *shortSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    for (index = indexOffset; index < sectionTitlesCount; index++) {
        
        NSMutableArray *usersArrayForSection = [tmpSectionsArray objectAtIndex:index];
        
        if ([usersArrayForSection count] != 0) {
            NSArray* sortedUsersArrayForSection = [collation sortedArrayFromArray:usersArrayForSection collationStringSelector:@selector(displayName)];
            [shortSectionsArray addObject:sortedUsersArrayForSection];
            [tmpSectionedContactsTitle addObject:[[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:(index - indexOffset)]];
        }
    }
    
    return [[SectionedContacts alloc] initWithContacts:shortSectionsArray andTitles:tmpSectionedContactsTitle andCount:contactsCount];
}

@end
