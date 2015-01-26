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

#import "MXCContact.h"
#import "MXCPhoneNumber.h"
#import "MXCEmail.h"

#import "MatrixSDKHandler.h"

// warn when there is a contacts list refresh
NSString *const kContactManagerRefreshNotification = @"kContactManagerRefreshNotification";

@interface ContactManager() {
    NSDate *lastSyncDate;
    NSMutableArray* deviceContactsList;
    
    BOOL hasStatusObserver;
}
@end

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
        
        // save the last sync date
        // to avoid resync the whole phonebook
        lastSyncDate = nil;
        
        // check if the application is allowed to list the contacts
        ABAuthorizationStatus cbStatus = ABAddressBookGetAuthorizationStatus();
        
        //
        hasStatusObserver = NO;
        
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
        }
    }
    
    return self;
}

-(void)dealloc {
    if (hasStatusObserver) {
        [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
    }
}

- (void)refresh
{
    MatrixSDKHandler* mxHandler = [MatrixSDKHandler sharedHandler];
    
    // remove any observer
    if (hasStatusObserver) {
        [mxHandler removeObserver:self forKeyPath:@"status"];
        hasStatusObserver = NO;
    }
    
    dispatch_async(processingQueue, ^{
        NSMutableArray* contactsList = [[NSMutableArray alloc] init];
        
        // can list tocal contacts
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            
            ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
            ABRecordRef      contactRecord;
            int              index;
            CFMutableArrayRef people = (CFMutableArrayRef)ABAddressBookCopyArrayOfAllPeople(ab);
            
            if (nil != people) {
                int peopleCount = CFArrayGetCount(people);
                
                for (index = 0; index < peopleCount; index++) {
                    contactRecord = (ABRecordRef)CFArrayGetValueAtIndex(people, index);
                    [contactsList addObject:[[MXCContact alloc] initWithABRecord:contactRecord]];
                }
                
                CFRelease(people);
            }
            
            if (ab) {
                CFRelease(ab);
            }
        }
        
        deviceContactsList = contactsList;
        
        if (mxHandler.mxSession) {
            [self manage3PIDS];
        } else {
            // display what you could have read
            dispatch_async(dispatch_get_main_queue(), ^{
                contacts = deviceContactsList;
                
                hasStatusObserver = YES;
                // wait that the mxSession is ready
                [mxHandler  addObserver:self forKeyPath:@"status" options:0 context:nil];
                // at least, display the known contacts
                [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerRefreshNotification object:nil userInfo:nil];
            });
        }
    });
}

// the local contacts are listed
// update their 3PIDs and their update
- (void) manage3PIDS {
    dispatch_async(processingQueue, ^{
        NSMutableArray* tmpContacts = nil;
        
        // initial sync
        if (!lastSyncDate) {
            // display the current device contacts
            tmpContacts = deviceContactsList;
        } else {
            // update with the known dict 3PID -> matrix ID
            [self updateMatrixIDDeviceContactsList];
            
            // build a merged contacts list until the 3PIDs lookups are performed
            NSMutableArray* mergedContactsList = [deviceContactsList mutableCopy];
            [self mergeMXUsers:mergedContactsList];
            tmpContacts = mergedContactsList;
        }
        lastSyncDate = [NSDate date];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // stored self.contacts in the right thread
            contacts = tmpContacts;
            // refresh the 3PIDS -> matrix IDs
            [self refreshMatrixIDs];
            // at least, display the known contacts
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerRefreshNotification object:nil userInfo:nil];
        });
    });
}

- (void) updateMatrixIDDeviceContactsList {
    // update the contacts info
    for(MXCContact* contact in deviceContactsList) {
        // the phonenumbers wil be managed later
        /*for(ConsolePhoneNumber* pn in contact.phoneNumbers) {
         if (pn.textNumber.length > 0) {
         
         // not yet added
         if ([pids indexOfObject:pn.textNumber] == NSNotFound) {
         [pids addObject:pn.textNumber];
         [medias addObject:@"msisdn"];
         }
         }
         }*/
        
        for(MXCEmail* email in contact.emailAddresses) {
            if (email.emailAddress.length > 0) {
                id matrixID = [matrixIDBy3PID valueForKey:email.emailAddress];
                
                if ([matrixID isKindOfClass:[NSString class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [email setMatrixID:matrixID];
                    });
                }
            }
        }
    }
}

// merge the knowns MXUsers with the contacts list
// return the number of modified / added contacts
- (int) mergeMXUsers:(NSMutableArray*)contactsList {
    // check if the some room users are not defined in the local contacts book
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // check if the user is already known
    NSArray* users = [mxHandler.mxSession users];
    NSArray* knownUserIDs = [matrixIDBy3PID allValues];
    
    int count = 0;
    
    for(MXUser* user in users) {
        
        if (!knownUserIDs || [knownUserIDs indexOfObject:user.userId] == NSNotFound) {
            MXCContact* contact = [[MXCContact alloc] initWithDisplayName:(user.displayname ? user.displayname : user.userId) matrixID:user.userId];
            
            [contactsList addObject:contact];
            count++;
        }
    }
    
    return count;
}

// refresh the 3PIDs -> Matrix ID list
// update the contact is required
- (void)refreshMatrixIDs {
    
    // build the request parameters
    NSMutableArray* pids = [[NSMutableArray alloc] init];
    NSMutableArray* medias = [[NSMutableArray alloc] init];
    
    for(MXCContact* contact in deviceContactsList) {
        // the phonenumbers are not managed
        /*for(ConsolePhoneNumber* pn in contact.phoneNumbers) {
         if (pn.textNumber.length > 0) {
         
         // not yet added
         if ([pids indexOfObject:pn.textNumber] == NSNotFound) {
         [pids addObject:pn.textNumber];
         [medias addObject:@"msisdn"];
         }
         }
         }*/
        
        for(MXCEmail* email in contact.emailAddresses) {
            if (email.emailAddress.length > 0) {
                
                // not yet added
                if ([pids indexOfObject:email.emailAddress] == NSNotFound) {
                    [pids addObject:email.emailAddress];
                    [medias addObject:@"email"];
                }
            }
        }
    }
    
    // get some pids
    if (pids.count > 0) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        if (mxHandler.mxRestClient) {
            [mxHandler.mxRestClient lookup3pids:pids
                                       forMedia:medias
                                        success:^(NSArray *userIds) {
                                            // sanity check
                                            if (userIds.count == pids.count) {
                                                
                                                matrixIDBy3PID = [[NSMutableDictionary alloc] initWithObjects:userIds forKeys:pids];
                                                
                                                [self updateMatrixIDDeviceContactsList];
                                                
                                                // add the MX users
                                                NSMutableArray* tmpContacts = [deviceContactsList mutableCopy];
                                                [self mergeMXUsers:tmpContacts];
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    contacts = tmpContacts;
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerRefreshNotification object:nil userInfo:nil];
                                                });
                                            }
                                        }
                                        failure:^(NSError *error) {
                                            // try later
                                            dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                [self refreshMatrixIDs];
                                            });
                                        }
             ];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MatrixSDKHandler sharedHandler].status == MatrixSDKHandlerStatusServerSyncDone) {
                
                if (hasStatusObserver) {
                    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
                    hasStatusObserver = NO;
                }
                
                [self manage3PIDS];
            }
        });
    }
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
    
    for (MXCContact *aContact in contactsList)
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
