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

#import "AppSettings.h"

// warn when there is a contacts list refresh
NSString *const kContactManagerContactsListRefreshNotification = @"kContactManagerContactsListRefreshNotification";

// the phonenumber has been internationalized
NSString *const kContactsDidInternationalizeNotification = @"kContactsDidInternationalizeNotification";

// get the 3PIDS in one requests
//#define CONTACTS_3PIDS_SYNC 1
// else checks the matrix IDs for each displayed contact

@interface ContactManager() {
    NSDate *lastSyncDate;
    NSMutableDictionary* deviceContactByContactID;
    
    //
    NSMutableArray* pending3PIDs;
    NSMutableArray* checked3PIDs;
    
    NSMutableDictionary* matrixContactByMatrixUserID;
    
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
        
        // other inits
        matrixContactByMatrixUserID = [[NSMutableDictionary alloc] init];
        
        // save the last sync date
        // to avoid resync the whole phonebook
        lastSyncDate = nil;
        
        // wait that the mxSession is ready
        [[AppSettings sharedSettings]  addObserver:self forKeyPath:@"syncLocalContacts" options:0 context:nil];
    }
    
    return self;
}

-(void)dealloc {
    if (hasStatusObserver) {
        [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
        [[AppSettings sharedSettings] removeObserver:self forKeyPath:@"syncLocalContacts"];
    }
}

// delete contacts info
- (void)reset {
    
    contacts = nil;
    
    lastSyncDate = nil;
    deviceContactByContactID = nil;
    matrixContactByMatrixUserID = nil;
    if (hasStatusObserver) {
        [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
        hasStatusObserver = NO;
    }
    
    [self saveMatrixIDsDict];
    [self saveDeviceContacts];
    [self saveContactBookInfo];

    // warn of the contacts list update
    [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerContactsListRefreshNotification object:nil userInfo:nil];
}

// refresh the international phonenumber of the contacts
- (void)internationalizePhoneNumbers:(NSString*)countryCode {
    NSArray* contactsSnapshot = self.contacts;
    
    for(MXCContact* contact in contactsSnapshot) {
        [contact internationalizePhonenumbers:countryCode];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kContactsDidInternationalizeNotification object:nil userInfo:nil];
}

- (void)fullRefresh {
    
    // check if the user allowed to sync local contacts
    if (![[AppSettings sharedSettings] syncLocalContacts]) {
        // if the user did not allow to sync local contacts
        // ignore this sync
        return;
    }
    
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
                    [self fullRefresh];
                });
                
            });
            
            CFRelease(ab);
        }
        
        return;
    }
    
    MatrixSDKHandler* mxHandler = [MatrixSDKHandler sharedHandler];
    
    // remove any observer
    if (hasStatusObserver) {
        [mxHandler removeObserver:self forKeyPath:@"status"];
        hasStatusObserver = NO;
    }
    
    pending3PIDs = [[NSMutableArray alloc] init];
    checked3PIDs = [[NSMutableArray alloc] init];

    // cold start
    // launch the dict from the file system
    // It is cached to improve UX.
    if (!matrixIDBy3PID) {
        [self loadMatrixIDsDict];
    }

    dispatch_async(processingQueue, ^{

        // in case of cold start
        // get the info from the file system
        if (!lastSyncDate) {
            // load cached contacts
            [self loadDeviceContacts];
            [self loadContactBookInfo];
            
            // no local contact -> assume that the last sync date is useless
            if (deviceContactByContactID.count == 0) {
                lastSyncDate = nil;
            }
        }
        
        BOOL contactBookUpdate = NO;
        
        NSMutableArray* deletedContactIDs = [[deviceContactByContactID allKeys] mutableCopy];
        
        // can list tocal contacts
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            
            ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
            ABRecordRef      contactRecord;
            CFIndex          index;
            CFMutableArrayRef people = (CFMutableArrayRef)ABAddressBookCopyArrayOfAllPeople(ab);
            
            if (nil != people) {
                CFIndex peopleCount = CFArrayGetCount(people);
                
                for (index = 0; index < peopleCount; index++) {
                    
                    contactRecord = (ABRecordRef)CFArrayGetValueAtIndex(people, index);
                    
                    NSString* contactID = [MXCContact contactID:contactRecord];
                    
                    // the contact still exists
                    [deletedContactIDs removeObject:contactID];
                    
                    if (lastSyncDate) {
                        // ignore unchanged contacts since the previous sync
                        CFDateRef lastModifDate = ABRecordCopyValue(contactRecord, kABPersonModificationDateProperty);
                        if (kCFCompareGreaterThan != CFDateCompare (lastModifDate, (__bridge CFDateRef)lastSyncDate, nil))
                        {
                            CFRelease(lastModifDate);
                            continue;
                        }
                        CFRelease(lastModifDate);
                    }
                    
                    contactBookUpdate = YES;
                    // update the contact
                    [deviceContactByContactID setValue:[[MXCContact alloc] initWithABRecord:contactRecord] forKey:contactID];
                }
                
                CFRelease(people);
            }
            
            if (ab) {
                CFRelease(ab);
            }
        }
        
        // some contacts have been deleted
        for (NSString* contactID in deletedContactIDs) {
            contactBookUpdate = YES;
            [deviceContactByContactID removeObjectForKey:contactID];
        }

        // something has been modified in the device contact book
        if (contactBookUpdate) {
            [self saveDeviceContacts];
        }
        
        lastSyncDate = [NSDate date];
        [self saveContactBookInfo];
    
        NSMutableArray* deviceContacts = [[deviceContactByContactID allValues] mutableCopy];
        
        if (mxHandler.mxSession) {
            [self manage3PIDS];
        } else {
            // display what you could have read
            dispatch_async(dispatch_get_main_queue(), ^{
                contacts = deviceContacts;
                
                hasStatusObserver = YES;
                // wait that the mxSession is ready
                [mxHandler  addObserver:self forKeyPath:@"status" options:0 context:nil];
                // at least, display the known contacts
                [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerContactsListRefreshNotification object:nil userInfo:nil];
            });
        }
    });
}

// the local contacts are listed
// update their 3PIDs and their update
- (void) manage3PIDS {
    dispatch_async(processingQueue, ^{
        NSMutableArray* tmpContacts = nil;
        
        // update with the known dict 3PID -> matrix ID
        [self updateMatrixIDDeviceContacts];
        
        tmpContacts = [[deviceContactByContactID allValues] mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // stored self.contacts in the right thread
            contacts = tmpContacts;
#if CONTACTS_3PIDS_SYNC
            // refresh the 3PIDS -> matrix IDs
            [self refreshMatrixIDs];
#else
            // nop
            // wait that refreshContactMatrixIDs  is called 
            
#endif
            // at least, display the known contacts
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerContactsListRefreshNotification object:nil userInfo:nil];
        });
    });
}

- (void) updateContactMatrixIDs:(MXCContact*) contact {
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

- (void) updateMatrixIDDeviceContacts {
    
    NSArray* deviceContacts = [deviceContactByContactID allValues];
    
    // update the contacts info
    for(MXCContact* contact in deviceContacts) {
        [self updateContactMatrixIDs:contact];
    }
}

#ifdef CONTACTS_3PIDS_SYNC
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
                                                [self saveMatrixIDsDict];
                                                [self updateMatrixIDDeviceContactsList];
                                                
                                                // add the MX users
                                                NSMutableArray* tmpContacts = [deviceContactsList mutableCopy];
                                                [self mergeMXUsers:tmpContacts];
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    contacts = tmpContacts;
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerContactsListRefreshNotification object:nil userInfo:nil];
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
#endif

// refresh matrix IDs
- (void)refreshContactMatrixIDs:(MXCContact*)contact {
#ifndef CONTACTS_3PIDS_SYNC
    if (!contact.isMatrixContact) {
        
        // check pending requests
        NSMutableArray* pids = [[NSMutableArray alloc] init];
        NSMutableArray* medias = [[NSMutableArray alloc] init];
        
        for(MXCEmail* email in contact.emailAddresses) {
            if (([pending3PIDs indexOfObject:email.emailAddress] == NSNotFound) && ([checked3PIDs indexOfObject:email.emailAddress] == NSNotFound)) {
                [pids addObject:email.emailAddress];
                [medias addObject:@"email"];
            }
        }
    
        if (pids.count > 0)  {
            [pending3PIDs addObjectsFromArray:pids];
            
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            
            if (mxHandler) {
                [mxHandler.mxRestClient lookup3pids:pids
                                           forMedia:medias
                                            success:^(NSArray *userIds) {
                                                // sanity check
                                                if (userIds.count == pids.count) {
                                                    
                                                    // update statuses table
                                                    [checked3PIDs addObjectsFromArray:pids];
                                                    for(NSString* pid in pids) {
                                                        [pending3PIDs removeObject:pid];
                                                    }
                                                    
                                                    BOOL isUpdated = NO;
                                                    NSMutableArray* matrixContactsToRemove = [[NSMutableArray alloc] init];
                                                    
                                                    // apply updates
                                                    if (pids.count > 0) {
                                                        for(int index = 0; index < pids.count; index++) {
                                                            NSString* matrixID = [userIds objectAtIndex:index];
                                                            NSString* pid = [pids objectAtIndex:index];
                                                            
                                                            // the dict is created on demand
                                                            if (!matrixIDBy3PID) {
                                                                [self loadMatrixIDsDict];
                                                            }
                                                         
                                                            id currentMatrixID = [matrixIDBy3PID valueForKey:pid];
                                                            
                                                            // do not keep useless info
                                                            if ([matrixID isKindOfClass:[NSString class]]) {
                                                                
                                                                // do not update if not required
                                                                if (![currentMatrixID isKindOfClass:[NSString class]] || ![(NSString*)currentMatrixID isEqualToString:matrixID]) {
                                                                    [matrixIDBy3PID setValue:matrixID forKey:pid];
                                                                    isUpdated = YES;
                                                                }
                                                                
                                                            } else {
                                                                if (currentMatrixID) {
                                                                    [matrixIDBy3PID removeObjectForKey:pid];
                                                                    isUpdated = YES;
                                                                }
                                                            }
                                                            
                                                            // is there a matrix contact with the same
                                                            if ([matrixContactByMatrixUserID objectForKey:matrixID]) {
                                                                [matrixContactsToRemove addObject:[matrixContactByMatrixUserID objectForKey:matrixID]];
                                                            }
                                                        }
                                                        
                                                        if (isUpdated) {
                                                            [self saveMatrixIDsDict];
                                                        }
                                                    }

                                                    // some matrix contacts will be replaced by this contact
                                                    if (matrixContactsToRemove.count > 0) {
                                                        [self updateContactMatrixIDs:contact];
                                                        
                                                        for(MXCContact* contactToRemove in matrixContactsToRemove) {
                                                            [self.contacts removeObject:contactToRemove];
                                                        }
    
                                                        // warn there is a global refresh
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerContactsListRefreshNotification object:nil userInfo:nil];
                                                    } else {
                                                        // update only this contact
                                                        [self updateContactMatrixIDs:contact];
                                                    }
                                                }
                                            }
                                            failure:^(NSError *error) {
                                                // try later
                                                dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                    [self refreshContactMatrixIDs:contact];
                                                });
                                            }];
            }
            else {
                dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self refreshContactMatrixIDs:contact];
                });
            }
        }
    }
#endif
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
    } else if ([@"syncLocalContacts" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fullRefresh];
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

#pragma mark - file caches

static NSString *matrixIDsDictFile = @"matrixIDsDict";
static NSString *localContactsFile = @"localContacts";
static NSString *contactsBookInfoFile = @"contacts";

- (void)saveMatrixIDsDict
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:matrixIDsDictFile];
    
    if (matrixIDBy3PID)
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:matrixIDBy3PID forKey:@"matrixIDsDict"];
        [encoder finishEncoding];
        
        [theData writeToFile:dataFilePath atomically:YES];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void)loadMatrixIDsDict
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:matrixIDsDictFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            id object = [decoder decodeObjectForKey:@"matrixIDsDict"];
            
            if ([object isKindOfClass:[NSDictionary class]]) {
                matrixIDBy3PID = [object mutableCopy];
            }
                
            [decoder finishDecoding];
        } @catch (NSException *exception) {
        }
    }

    if (!matrixIDBy3PID) {
        matrixIDBy3PID = [[NSMutableDictionary alloc] init];
    }
}

- (void) saveDeviceContacts {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:localContactsFile];
    
    if (deviceContactByContactID && (deviceContactByContactID.count > 0))
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:deviceContactByContactID forKey:@"deviceContactByContactID"];
        
        [encoder finishEncoding];
        
        [theData writeToFile:dataFilePath atomically:YES];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void) loadDeviceContacts {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:localContactsFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            id object = [decoder decodeObjectForKey:@"deviceContactByContactID"];
            
            if ([object isKindOfClass:[NSDictionary class]]) {
                deviceContactByContactID = [object mutableCopy];
            }
            
            [decoder finishDecoding];
        } @catch (NSException *exception) {
            lastSyncDate = nil;
        }
    }
    
    if (!deviceContactByContactID) {
        deviceContactByContactID = [[NSMutableDictionary alloc] init];
    }
}

- (void) saveContactBookInfo {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:contactsBookInfoFile];
    
    if (lastSyncDate)
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:lastSyncDate forKey:@"lastSyncDate"];
        
        [encoder finishEncoding];
        
        [theData writeToFile:dataFilePath atomically:YES];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void) loadContactBookInfo {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:contactsBookInfoFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            lastSyncDate = [decoder decodeObjectForKey:@"lastSyncDate"];
            
            [decoder finishDecoding];
        } @catch (NSException *exception) {
            lastSyncDate = nil;
        }
    }
}


@end
