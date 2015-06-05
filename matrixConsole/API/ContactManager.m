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

#import "MXKAppSettings.h"

NSString *const kContactManagerDidUpdateContactsNotification = @"kContactManagerDidUpdateContactsNotification";
NSString *const kContactManagerDidUpdateContactMatrixIDsNotification = @"kContactManagerDidUpdateContactMatrixIDsNotification";

NSString *const kContactManagerMatrixUserPresenceChangeNotification = @"kContactManagerMatrixUserPresenceChangeNotification";
NSString *const kContactManagerMatrixPresenceKey = @"kContactManagerMatrixPresenceKey";

NSString *const kContactManagerDidInternationalizeNotification = @"kContactManagerDidInternationalizeNotification";

@interface ContactManager()
{
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    
    /**
     Presence listener by matrix session
     */
    NSMutableArray *mxPresenceListeners;
    
    /**
     Matrix id linked to 3PID.
     */
    NSMutableDictionary* matrixIDBy3PID;
    
    dispatch_queue_t processingQueue;
    BOOL isLoading;
    NSDate *lastSyncDate;
    NSMutableDictionary* deviceContactByContactID;
    
    // Keep history of 3PID lookup requests
    NSMutableArray* pending3PIDs;
    NSMutableArray* checked3PIDs;
}

/**
 The current REST client defined with the identity server.
 */
@property (nonatomic) MXRestClient *identityRESTClient;
@end

@implementation ContactManager

#pragma mark Singleton Methods
static ContactManager* sharedContactManager = nil;

+ (id)sharedManager
{
    @synchronized(self)
    {
        if(sharedContactManager == nil)
            sharedContactManager = [[self alloc] init];
    }
    return sharedContactManager;
}

#pragma mark -

-(ContactManager *)init
{
    if (self = [super init])
    {
        NSString *label = [NSString stringWithFormat:@"ConsoleMatrix.%@.Contacts", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        
        processingQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // save the last sync date
        // to avoid resync the whole phonebook
        lastSyncDate = nil;
        
        // Observe related settings change
        [[MXKAppSettings standardAppSettings]  addObserver:self forKeyPath:@"syncLocalContacts" options:0 context:nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self reset];
    
    [[MXKAppSettings standardAppSettings] removeObserver:self forKeyPath:@"syncLocalContacts"];
    
    processingQueue = nil;
}

#pragma mark -

- (void)addMatrixSession:(MXSession*)mxSession
{
    if (!mxSession)
    {
        return;
    }
    
    // Check conditions to trigger a full refresh of contacts matrix ids
    BOOL shouldUpdateContactsMatrixIDs = (self.enableFullMatrixIdSyncOnContactsDidLoad && !isLoading && !_identityRESTClient);
    
    if (!mxSessionArray)
    {
        mxSessionArray = [NSMutableArray array];
    }
    if (!mxPresenceListeners)
    {
        mxPresenceListeners = [NSMutableArray array];
    }
    
    if ([mxSessionArray indexOfObject:mxSession] == NSNotFound)
    {
        [mxSessionArray addObject:mxSession];
        
        // Register a listener for on matrix presence events
        id presenceListener = [mxSession listenToEventsOfTypes:@[kMXEventTypeStringPresence]
                                                       onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
                               // consider only live event
                               if (direction == MXEventDirectionForwards)
                               {
                                   NSArray *matrixIDs = [matrixIDBy3PID allValues];
                                   if ([matrixIDs indexOfObject:event.userId] != NSNotFound) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerMatrixUserPresenceChangeNotification object:event.userId userInfo:@{kContactManagerMatrixPresenceKey:event.content[@"presence"]}];
                                   }
                               }
                           }];
        
        [mxPresenceListeners addObject:presenceListener];
    }
    
    if (shouldUpdateContactsMatrixIDs)
    {
        [self updateContactsMatrixIDs];
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    if (!mxSession)
    {
        return;
    }
    
    NSUInteger index = [mxSessionArray indexOfObject:mxSession];
    if (index != NSNotFound)
    {
        id presenceListener = [mxPresenceListeners objectAtIndex:index];
        [mxSession removeListener:presenceListener];
        
        [mxPresenceListeners removeObjectAtIndex:index];
        [mxSessionArray removeObjectAtIndex:index];
        
        // Reset the current rest client (It will be rebuild if need)
        _identityRESTClient = nil;
        
        // Reset history of 3PID lookup requests
        pending3PIDs = nil;
        checked3PIDs = nil;
    }
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (NSArray*)contacts
{
    // Return nil if the loading step is in progress.
    if (isLoading)
    {
        return nil;
    }
    
    return [deviceContactByContactID allValues];
}

- (void)setIdentityServer:(NSString *)identityServer
{
    _identityServer = identityServer;
    
    if (identityServer)
    {
        _identityRESTClient = [[MXRestClient alloc] initWithHomeServer:nil];
        _identityRESTClient.identityServer = identityServer;
        
        if (self.enableFullMatrixIdSyncOnContactsDidLoad) {
            [self updateContactsMatrixIDs];
        }
    }
    else
    {
        _identityRESTClient = nil;
    }
    
    // Reset history of 3PID lookup requests
    pending3PIDs = nil;
    checked3PIDs = nil;
}

- (MXRestClient*)identityRESTClient
{
    if (!_identityRESTClient)
    {
        if (self.identityServer)
        {
            _identityRESTClient = [[MXRestClient alloc] initWithHomeServer:nil];
            _identityRESTClient.identityServer = self.identityServer;
        }
        else if (mxSessionArray.count)
        {
            MXSession *mxSession = [mxSessionArray firstObject];
            _identityRESTClient = [[MXRestClient alloc] initWithHomeServer:nil];
            _identityRESTClient.identityServer = mxSession.matrixRestClient.identityServer;
        }
    }
    
    return _identityRESTClient;
}

#pragma mark -

- (void)loadContacts
{
    // check if the user allowed to sync local contacts
    if (![[MXKAppSettings standardAppSettings] syncLocalContacts])
    {
        // if the user did not allow to sync local contacts
        // ignore this sync
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidUpdateContactsNotification object:nil userInfo:nil];
        return;
    }
    
    // check if the application is allowed to list the contacts
    ABAuthorizationStatus cbStatus = ABAddressBookGetAuthorizationStatus();
    
    // did not yet request the access
    if (cbStatus == kABAuthorizationStatusNotDetermined)
    {
        // request address book access
        ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
        
        if (ab)
        {
            ABAddressBookRequestAccessWithCompletion(ab, ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadContacts];
                });
                
            });
            
            CFRelease(ab);
        }
        
        return;
    }
    
    isLoading = YES;
    
    // Reset history of 3PID lookup requests
    pending3PIDs = nil;
    checked3PIDs = nil;
    
    // cold start
    // launch the dict from the file system
    // It is cached to improve UX.
    if (!matrixIDBy3PID)
    {
        [self loadMatrixIDsDict];
    }
    
    dispatch_async(processingQueue, ^{
        
        // in case of cold start
        // get the info from the file system
        if (!lastSyncDate)
        {
            // load cached contacts
            [self loadDeviceContacts];
            [self loadContactBookInfo];
            
            // no local contact -> assume that the last sync date is useless
            if (deviceContactByContactID.count == 0)
            {
                lastSyncDate = nil;
            }
        }
        
        BOOL contactBookUpdate = NO;
        
        NSMutableArray* deletedContactIDs = [NSMutableArray arrayWithArray:[deviceContactByContactID allKeys]];
        
        // can list local contacts?
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
        {
            NSString* countryCode = [[MXKAppSettings standardAppSettings] phonebookCountryCode];
            
            ABAddressBookRef ab = ABAddressBookCreateWithOptions(nil, nil);
            ABRecordRef      contactRecord;
            CFIndex          index;
            CFMutableArrayRef people = (CFMutableArrayRef)ABAddressBookCopyArrayOfAllPeople(ab);
            
            if (nil != people)
            {
                CFIndex peopleCount = CFArrayGetCount(people);
                
                for (index = 0; index < peopleCount; index++)
                {
                    contactRecord = (ABRecordRef)CFArrayGetValueAtIndex(people, index);
                    
                    NSString* contactID = [MXCContact contactID:contactRecord];
                    
                    // the contact still exists
                    [deletedContactIDs removeObject:contactID];
                    
                    if (lastSyncDate)
                    {
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
                    
                    MXCContact* contact = [[MXCContact alloc] initWithABRecord:contactRecord];
                    
                    if (countryCode)
                    {
                        [contact internationalizePhonenumbers:countryCode];
                    }
                    
                    // update the contact
                    [deviceContactByContactID setValue:contact forKey:contactID];;
                }
                
                CFRelease(people);
            }
            
            if (ab)
            {
                CFRelease(ab);
            }
        }
        
        // some contacts have been deleted
        for (NSString* contactID in deletedContactIDs)
        {
            contactBookUpdate = YES;
            [deviceContactByContactID removeObjectForKey:contactID];
        }
        
        // something has been modified in the device contact book
        if (contactBookUpdate)
        {
            [self saveDeviceContacts];
        }
        
        lastSyncDate = [NSDate date];
        [self saveContactBookInfo];
        
        // Update loaded contacts with the known dict 3PID -> matrix ID
        [self updateMatrixIDDeviceContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Contacts are loaded, post a notification
            isLoading = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidUpdateContactsNotification object:nil userInfo:nil];
            
            if (self.enableFullMatrixIdSyncOnContactsDidLoad) {
                [self updateContactsMatrixIDs];
            }
        });
    });
}

// refresh matrix IDs
- (void)updateMatrixIDsForContact:(MXCContact *)contact
{
    if (!contact.isMatrixContact && self.identityRESTClient)
    {
        if (!pending3PIDs)
        {
            pending3PIDs = [[NSMutableArray alloc] init];
            checked3PIDs = [[NSMutableArray alloc] init];
        }
        
        // Retrieve all 3PIDs of the contact by checking pending requests
        NSMutableArray* pids = [[NSMutableArray alloc] init];
        NSMutableArray* medias = [[NSMutableArray alloc] init];
        for(MXCEmail* email in contact.emailAddresses)
        {
            if (([pending3PIDs indexOfObject:email.emailAddress] == NSNotFound) && ([checked3PIDs indexOfObject:email.emailAddress] == NSNotFound))
            {
                [pids addObject:email.emailAddress];
                [medias addObject:@"email"];
            }
        }
        
        if (pids.count > 0)
        {
            [pending3PIDs addObjectsFromArray:pids];
            
            [self.identityRESTClient lookup3pids:pids
                                        forMedia:medias
                                         success:^(NSArray *userIds) {
                                             // sanity check
                                             if (userIds.count == pids.count)
                                             {
                                                 // Update status table
                                                 [checked3PIDs addObjectsFromArray:pids];
                                                 for(NSString* pid in pids)
                                                 {
                                                     [pending3PIDs removeObject:pid];
                                                 }
                                                 
                                                 // Look for updates
                                                 BOOL isUpdated = NO;
                                                 for (int index = 0; index < pids.count; index++)
                                                 {
                                                     id matrixID = [userIds objectAtIndex:index];
                                                     NSString* pid = [pids objectAtIndex:index];
                                                     NSString *currentMatrixID = [matrixIDBy3PID valueForKey:pid];
                                                     
                                                     if ([matrixID isEqual:[NSNull null]])
                                                     {
                                                         if (currentMatrixID)
                                                         {
                                                             [matrixIDBy3PID removeObjectForKey:pid];
                                                             isUpdated = YES;
                                                         }
                                                     }
                                                     else if ([matrixID isKindOfClass:[NSString class]])
                                                     {
                                                         if (![currentMatrixID isEqualToString:matrixID])
                                                         {
                                                             [matrixIDBy3PID setValue:matrixID forKey:pid];
                                                             isUpdated = YES;
                                                         }
                                                     }
                                                 }
                                                 
                                                 if (isUpdated)
                                                 {
                                                     [self saveMatrixIDsDict];
                                                 }
                                                 
                                                 // Update only this contact
                                                 [self updateContactMatrixIDs:contact];
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidUpdateContactMatrixIDsNotification object:contact.contactID userInfo:nil];
                                                 });
                                             }
                                         }
                                         failure:^(NSError *error) {
                                             NSLog(@"[ContactManager] lookup3pids failed %@", error);
                                             
                                             // try later
                                             dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                 [self updateMatrixIDsForContact:contact];
                                             });
                                         }];
        }
    }
}


- (void)updateContactsMatrixIDs
{
    // Check if at least an identity server is available, and if the loading step is not in progress
    if (!self.identityRESTClient || isLoading)
    {
        return;
    }
    
    // Refresh the 3PIDs -> Matrix ID mapping
    dispatch_async(processingQueue, ^{
        
        NSArray* contactsSnapshot = [deviceContactByContactID allValues];
        
        // Retrieve all 3PIDs
        NSMutableArray* pids = [[NSMutableArray alloc] init];
        NSMutableArray* medias = [[NSMutableArray alloc] init];
        for(MXCContact* contact in contactsSnapshot)
        {
            // the phonenumbers are not managed
            /*for(ConsolePhoneNumber* pn in contact.phoneNumbers)
             {
             if (pn.textNumber.length > 0)
             {
             
             // not yet added
             if ([pids indexOfObject:pn.textNumber] == NSNotFound)
             {
             [pids addObject:pn.textNumber];
             [medias addObject:@"msisdn"];
             }
             }
             }*/
            
            for(MXCEmail* email in contact.emailAddresses)
            {
                if (email.emailAddress.length > 0)
                {
                    // not yet added
                    if ([pids indexOfObject:email.emailAddress] == NSNotFound)
                    {
                        [pids addObject:email.emailAddress];
                        [medias addObject:@"email"];
                    }
                }
            }
        }
        
        // Update 3PIDs mapping
        if (pids.count > 0)
        {
            [self.identityRESTClient lookup3pids:pids
                                        forMedia:medias
                                         success:^(NSArray *userIds) {
                                             // Sanity check
                                             if (userIds.count == pids.count)
                                             {
                                                 matrixIDBy3PID = [[NSMutableDictionary alloc] initWithObjects:userIds forKeys:pids];
                                                 [self saveMatrixIDsDict];
                                                 [self updateMatrixIDDeviceContacts];
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidUpdateContactMatrixIDsNotification object:nil userInfo:nil];
                                                 });
                                             }
                                         }
                                         failure:^(NSError *error) {
                                             NSLog(@"[ContactManager] lookup3pids failed %@", error);
                                             
                                             // try later
                                             dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                 [self updateContactsMatrixIDs];
                                             });
                                         }];
        }
        else
        {
            matrixIDBy3PID = nil;
            [self saveMatrixIDsDict];
        }
    });
}

- (void)reset
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
    
    isLoading = NO;
    matrixIDBy3PID = nil;
    [self saveMatrixIDsDict];
    
    deviceContactByContactID = nil;
    [self saveDeviceContacts];
    
    lastSyncDate = nil;
    [self saveContactBookInfo];
    
    while (mxSessionArray.count) {
        [self removeMatrixSession:mxSessionArray.lastObject];
    }
    mxSessionArray = nil;
    mxPresenceListeners = nil;
    _identityServer = nil;
    _identityRESTClient = nil;
    
    pending3PIDs = nil;
    checked3PIDs = nil;
    
    // warn of the contacts list update
    [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidUpdateContactsNotification object:nil userInfo:nil];
}

// refresh the international phonenumber of the contacts
- (void)internationalizePhoneNumbers:(NSString*)countryCode
{
    dispatch_async(processingQueue, ^{
        NSArray* contactsSnapshot = [deviceContactByContactID allValues];
        
        for(MXCContact* contact in contactsSnapshot)
        {
            [contact internationalizePhonenumbers:countryCode];
        }
        
        [self saveDeviceContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactManagerDidInternationalizeNotification object:nil userInfo:nil];
        });
    });
}

- (SectionedContacts *)getSectionedContacts:(NSArray*)contactsList
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    int indexOffset = 0;
    
    NSInteger index, sectionTitlesCount = [[collation sectionTitles] count];
    NSMutableArray *tmpSectionsArray = [[NSMutableArray alloc] initWithCapacity:(sectionTitlesCount)];
    
    sectionTitlesCount += indexOffset;
    
    for (index = 0; index < sectionTitlesCount; index++)
    {
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
    
    for (index = indexOffset; index < sectionTitlesCount; index++)
    {
        
        NSMutableArray *usersArrayForSection = [tmpSectionsArray objectAtIndex:index];
        
        if ([usersArrayForSection count] != 0)
        {
            NSArray* sortedUsersArrayForSection = [collation sortedArrayFromArray:usersArrayForSection collationStringSelector:@selector(displayName)];
            [shortSectionsArray addObject:sortedUsersArrayForSection];
            [tmpSectionedContactsTitle addObject:[[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:(index - indexOffset)]];
        }
    }
    
    return [[SectionedContacts alloc] initWithContacts:shortSectionsArray andTitles:tmpSectionedContactsTitle andCount:contactsCount];
}

#pragma mark - Internals

- (void)updateContactMatrixIDs:(MXCContact*) contact
{
    // the phonenumbers wil be managed later
    /*for(ConsolePhoneNumber* pn in contact.phoneNumbers)
     {
     if (pn.textNumber.length > 0)
     {
     
     // not yet added
     if ([pids indexOfObject:pn.textNumber] == NSNotFound)
     {
     [pids addObject:pn.textNumber];
     [medias addObject:@"msisdn"];
     }
     }
     }*/
    
    for(MXCEmail* email in contact.emailAddresses)
    {
        if (email.emailAddress.length > 0)
        {
            id matrixID = [matrixIDBy3PID valueForKey:email.emailAddress];
            
            if ([matrixID isKindOfClass:[NSString class]])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [email setMatrixID:matrixID];
                });
            }
        }
    }
}

- (void)updateMatrixIDDeviceContacts
{
    NSArray* deviceContacts = [deviceContactByContactID allValues];
    
    // update the contacts info
    for(MXCContact* contact in deviceContacts)
    {
        [self updateContactMatrixIDs:contact];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"syncLocalContacts" isEqualToString:keyPath])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadContacts];
        });
    }
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
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            id object = [decoder decodeObjectForKey:@"matrixIDsDict"];
            
            if ([object isKindOfClass:[NSDictionary class]])
            {
                matrixIDBy3PID = [object mutableCopy];
            }
            
            [decoder finishDecoding];
        }
        @catch (NSException *exception)
        {
        }
    }
    
    if (!matrixIDBy3PID)
    {
        matrixIDBy3PID = [[NSMutableDictionary alloc] init];
    }
}

- (void)saveDeviceContacts
{
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

- (void)loadDeviceContacts
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:localContactsFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            id object = [decoder decodeObjectForKey:@"deviceContactByContactID"];
            
            if ([object isKindOfClass:[NSDictionary class]])
            {
                deviceContactByContactID = [object mutableCopy];
            }
            
            [decoder finishDecoding];
        } @catch (NSException *exception)
        {
            lastSyncDate = nil;
        }
    }
    
    if (!deviceContactByContactID)
    {
        deviceContactByContactID = [[NSMutableDictionary alloc] init];
    }
}

- (void)saveContactBookInfo
{
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

- (void)loadContactBookInfo
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [documentsDirectory stringByAppendingPathComponent:contactsBookInfoFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
        
    {
        // the file content could be corrupted
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
            
            lastSyncDate = [decoder decodeObjectForKey:@"lastSyncDate"];
            
            [decoder finishDecoding];
        } @catch (NSException *exception)
        {
            lastSyncDate = nil;
        }
    }
}

@end
