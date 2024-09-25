/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKContactManager.h"

#import "MXKContact.h"

#import "MXKAppSettings.h"
#import "MXKTools.h"
#import "NSBundle+MatrixKit.h"
#import <MatrixSDK/MXAes.h>
#import <MatrixSDK/MXRestClient.h>
#import <MatrixSDK/MXKeyProvider.h>

#import "MXKSwiftHeader.h"

NSString *const kMXKContactManagerDidUpdateMatrixContactsNotification = @"kMXKContactManagerDidUpdateMatrixContactsNotification";

NSString *const kMXKContactManagerDidUpdateLocalContactsNotification = @"kMXKContactManagerDidUpdateLocalContactsNotification";
NSString *const kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification = @"kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification";

NSString *const kMXKContactManagerMatrixUserPresenceChangeNotification = @"kMXKContactManagerMatrixUserPresenceChangeNotification";
NSString *const kMXKContactManagerMatrixPresenceKey = @"kMXKContactManagerMatrixPresenceKey";

NSString *const kMXKContactManagerDidInternationalizeNotification = @"kMXKContactManagerDidInternationalizeNotification";

NSString *const MXKContactManagerDataType = @"org.matrix.kit.MXKContactManagerDataType";

@interface MXKContactManager()
{
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    id mxSessionStateObserver;
    id mxSessionNewSyncedRoomObserver;
    
    /**
     Listeners registered on matrix presence and membership events (one by matrix session)
     */
    NSMutableArray *mxEventListeners;
    
    /**
     Local contacts handling
     */
    BOOL isLocalContactListRefreshing;
    dispatch_queue_t processingQueue;
    NSDate *lastSyncDate;
    // Local contacts by contact Id
    NSMutableDictionary* localContactByContactID;
    NSMutableArray* localContactsWithMethods;
    NSMutableArray* splitLocalContacts;
    
    // Matrix id linked to 3PID.
    NSMutableDictionary<NSString*, NSString*> *matrixIDBy3PID;
    
    /**
     Matrix contacts handling
     */
    // Matrix contacts by contact Id
    NSMutableDictionary* matrixContactByContactID;
    // Matrix contacts by matrix id
    NSMutableDictionary* matrixContactByMatrixID;
}

@end

@implementation MXKContactManager
@synthesize contactManagerMXRoomSource;

#pragma mark Singleton Methods

+ (instancetype)sharedManager
{
    static MXKContactManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MXKContactManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark -

-(MXKContactManager *)init
{
    if (self = [super init])
    {
        NSString *label = [NSString stringWithFormat:@"MatrixKit.%@.Contacts", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        
        [self deleteOldFiles];
        
        processingQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // save the last sync date
        // to avoid resync the whole phonebook
        lastSyncDate = nil;
        
        self.contactManagerMXRoomSource = MXKContactManagerMXRoomSourceDirectChats;
        
        // Observe related settings change
        [[MXKAppSettings standardAppSettings]  addObserver:self forKeyPath:@"syncLocalContacts" options:0 context:nil];
        [[MXKAppSettings standardAppSettings]  addObserver:self forKeyPath:@"phonebookCountryCode" options:0 context:nil];

        [self registerAccountDataDidChangeIdentityServerNotification];
        self.allowLocalContactsAccess = YES;
    }
    
    return self;
}

-(void)dealloc
{
    matrixIDBy3PID = nil;

    localContactByContactID = nil;
    localContactsWithMethods = nil;
    splitLocalContacts = nil;
    
    matrixContactByContactID = nil;
    matrixContactByMatrixID = nil;
    
    lastSyncDate = nil;
    
    while (mxSessionArray.count) {
        [self removeMatrixSession:mxSessionArray.lastObject];
    }
    mxSessionArray = nil;
    mxEventListeners = nil;
    
    [[MXKAppSettings standardAppSettings] removeObserver:self forKeyPath:@"syncLocalContacts"];
    [[MXKAppSettings standardAppSettings] removeObserver:self forKeyPath:@"phonebookCountryCode"];
    
    processingQueue = nil;
}

#pragma mark -

- (void)addMatrixSession:(MXSession*)mxSession
{
    if (!mxSessionArray)
    {
        mxSessionArray = [NSMutableArray array];
    }
    if (!mxEventListeners)
    {
        mxEventListeners = [NSMutableArray array];
    }
    
    if ([mxSessionArray indexOfObject:mxSession] == NSNotFound)
    {
        [mxSessionArray addObject:mxSession];
        
        MXWeakify(self);
        
        // Register a listener on matrix presence and membership events
        id eventListener = [mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomMember, kMXEventTypeStringPresence]
                                                       onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                                           
                               MXStrongifyAndReturnIfNil(self);
                                                           
                               // Consider only live event
                               if (direction == MXTimelineDirectionForwards)
                               {
                                   // Consider first presence events
                                   if (event.eventType == MXEventTypePresence)
                                   {
                                       // Check whether the concerned matrix user belongs to at least one contact.
                                       BOOL isMatched = ([self->matrixContactByMatrixID objectForKey:event.sender] != nil);
                                       if (!isMatched)
                                       {
                                           NSArray *matrixIDs = [self->matrixIDBy3PID allValues];
                                           isMatched = ([matrixIDs indexOfObject:event.sender] != NSNotFound);
                                       }
                                       
                                       if (isMatched) {
                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerMatrixUserPresenceChangeNotification object:event.sender userInfo:@{kMXKContactManagerMatrixPresenceKey:event.content[@"presence"]}];
                                       }
                                   }
                                   // Else the event type is MXEventTypeRoomMember.
                                   // Ignore here membership events if the session is not running yet,
                                   // Indeed all the contacts are refreshed when session state becomes running.
                                   else if (mxSession.state == MXSessionStateRunning)
                                   {
                                       // Update matrix contact list on membership change
                                       [self updateMatrixContactWithID:event.sender];
                                   }
                               }
                           }];
        
        [mxEventListeners addObject:eventListener];
        
        // Update matrix contact list in case of new synced one-to-one room
        if (!mxSessionNewSyncedRoomObserver)
        {
            mxSessionNewSyncedRoomObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomInitialSyncNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                
                MXStrongifyAndReturnIfNil(self);
                
                // create contact for known room members
                if (self.contactManagerMXRoomSource != MXKContactManagerMXRoomSourceNone)
                {
                    MXRoom *room = notif.object;
                    [room state:^(MXRoomState *roomState) {

                        MXRoomMembers *roomMembers = roomState.members;

                        NSArray *members = roomMembers.members;

                        // Consider only 1:1 chat for MXKMemberContactCreationOneToOneRoom
                        // or adding all
                        if (((members.count == 2) && (self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceDirectChats)) || (self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceAll))
                        {
                            NSString* myUserId = room.mxSession.myUser.userId;

                            for (MXRoomMember* member in members)
                            {
                                if ([member.userId isEqualToString:myUserId])
                                {
                                    [self updateMatrixContactWithID:member.userId];
                                }
                            }
                        }
                    }];
                }
            }];
        }
        
        // Update all matrix contacts as soon as matrix session is ready
        if (!mxSessionStateObserver) {
            mxSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                
                MXStrongifyAndReturnIfNil(self);
                
                MXSession *mxSession = notif.object;
                
                if ([self->mxSessionArray indexOfObject:mxSession] != NSNotFound)
                {
                    if ((mxSession.state == MXSessionStateStoreDataReady) || (mxSession.state == MXSessionStateRunning)) {
                        [self refreshMatrixContacts];
                    }
                }
            }];
        }

        // refreshMatrixContacts can take time. Delay its execution to not overload
        // launch of apps that call [MXKContactManager addMatrixSession] at startup
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshMatrixContacts];
        });
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    NSUInteger index = [mxSessionArray indexOfObject:mxSession];
    if (index != NSNotFound)
    {
        id eventListener = [mxEventListeners objectAtIndex:index];
        [mxSession removeListener:eventListener];
        
        [mxEventListeners removeObjectAtIndex:index];
        [mxSessionArray removeObjectAtIndex:index];
        
        if (!mxSessionArray.count) {
            if (mxSessionStateObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:mxSessionStateObserver];
                mxSessionStateObserver = nil;
            }
            
            if (mxSessionNewSyncedRoomObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:mxSessionNewSyncedRoomObserver];
                mxSessionNewSyncedRoomObserver = nil;
            }
        }
        
        // Update matrix contacts list
        [self refreshMatrixContacts];
    }
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}


- (NSArray*)matrixContacts
{
    NSParameterAssert([NSThread isMainThread]);

    return [matrixContactByContactID allValues];
}

- (NSArray*)localContacts
{
    NSParameterAssert([NSThread isMainThread]);

    // Return nil if the loading step is in progress.
    if (isLocalContactListRefreshing)
    {
        return nil;
    }
    
    return [localContactByContactID allValues];
}

- (NSArray*)localContactsWithMethods
{
    NSParameterAssert([NSThread isMainThread]);

    // Return nil if the loading step is in progress.
    if (isLocalContactListRefreshing)
    {
        return nil;
    }
    
    // Check whether the array must be prepared
    if (!localContactsWithMethods)
    {
        // List all the local contacts with emails and/or phones
        NSArray *localContacts = self.localContacts;
        localContactsWithMethods = [NSMutableArray arrayWithCapacity:localContacts.count];
        
        for (MXKContact* contact in localContacts)
        {
            if (contact.emailAddresses)
            {
                [localContactsWithMethods addObject:contact];
            }
            else if (contact.phoneNumbers)
            {
                [localContactsWithMethods addObject:contact];
            }
        }
    }
    
    return localContactsWithMethods;
}

- (NSArray*)localContactsSplitByContactMethod
{
   NSParameterAssert([NSThread isMainThread]);

    // Return nil if the loading step is in progress.
    if (isLocalContactListRefreshing)
    {
        return nil;
    }
    
    // Check whether the array must be prepared
    if (!splitLocalContacts)
    {
        // List all the local contacts with contact methods
        NSArray *contactsArray = self.localContactsWithMethods;
        
        splitLocalContacts = [NSMutableArray arrayWithCapacity:contactsArray.count];
        
        for (MXKContact* contact in contactsArray)
        {
            NSArray *emails = contact.emailAddresses;
            NSArray *phones = contact.phoneNumbers;
            
            if (emails.count + phones.count > 1)
            {
                for (MXKEmail *email in emails)
                {
                    MXKContact *splitContact = [[MXKContact alloc] initContactWithDisplayName:contact.displayName emails:@[email] phoneNumbers:nil andThumbnail:contact.thumbnail];
                    [splitLocalContacts addObject:splitContact];
                }
                
                for (MXKPhoneNumber *phone in phones)
                {
                    MXKContact *splitContact = [[MXKContact alloc] initContactWithDisplayName:contact.displayName emails:nil phoneNumbers:@[phone] andThumbnail:contact.thumbnail];
                    [splitLocalContacts addObject:splitContact];
                }
            }
            else if (emails.count + phones.count)
            {
                [splitLocalContacts addObject:contact];
            }
        }
        
        // Sort alphabetically the resulting list
        [self sortAlphabeticallyContacts:splitLocalContacts];
    }
    
    return splitLocalContacts;
}


//- (void)localContactsSplitByContactMethod:(void (^)(NSArray<MXKContact*> *localContactsSplitByContactMethod))onComplete
//{
//    NSParameterAssert([NSThread isMainThread]);
//
//    // Return nil if the loading step is in progress.
//    if (isLocalContactListRefreshing)
//    {
//        onComplete(nil);
//        return;
//    }
//    
//    // Check whether the array must be prepared
//    if (!splitLocalContacts)
//    {
//        // List all the local contacts with contact methods
//        NSArray *contactsArray = self.localContactsWithMethods;
//        
//        splitLocalContacts = [NSMutableArray arrayWithCapacity:contactsArray.count];
//        
//        for (MXKContact* contact in contactsArray)
//        {
//            NSArray *emails = contact.emailAddresses;
//            NSArray *phones = contact.phoneNumbers;
//            
//            if (emails.count + phones.count > 1)
//            {
//                for (MXKEmail *email in emails)
//                {
//                    MXKContact *splitContact = [[MXKContact alloc] initContactWithDisplayName:contact.displayName emails:@[email] phoneNumbers:nil andThumbnail:contact.thumbnail];
//                    [splitLocalContacts addObject:splitContact];
//                }
//                
//                for (MXKPhoneNumber *phone in phones)
//                {
//                    MXKContact *splitContact = [[MXKContact alloc] initContactWithDisplayName:contact.displayName emails:nil phoneNumbers:@[phone] andThumbnail:contact.thumbnail];
//                    [splitLocalContacts addObject:splitContact];
//                }
//            }
//            else if (emails.count + phones.count)
//            {
//                [splitLocalContacts addObject:contact];
//            }
//        }
//        
//        // Sort alphabetically the resulting list
//        [self sortAlphabeticallyContacts:splitLocalContacts];
//    }
//    
//    onComplete(splitLocalContacts);
//}

- (NSArray*)directMatrixContacts
{
    NSParameterAssert([NSThread isMainThread]);

    NSMutableDictionary *directContacts = [NSMutableDictionary dictionary];
    
    NSArray *mxSessions = self.mxSessions;
    
    for (MXSession *mxSession in mxSessions)
    {
        // Check all existing users for whom a direct chat exists
        NSArray *mxUserIds = mxSession.directRooms.allKeys;
        
        for (NSString *mxUserId in mxUserIds)
        {
            MXKContact* contact = [matrixContactByMatrixID objectForKey:mxUserId];
            
            // Sanity check - the contact must be already defined here
            if (contact)
            {
                [directContacts setValue:contact forKey:mxUserId];
            }
        }
    }
    
    return directContacts.allValues;
}

// The current identity service used with the contact manager
- (MXIdentityService*)identityService
{
    // For the moment, only use the one of the first session
    MXSession *mxSession = [mxSessionArray firstObject];
    return mxSession.identityService;
}

- (BOOL)isUsersDiscoveringEnabled
{
    // Check whether the 3pid lookup is available
    return (self.discoverUsersBoundTo3PIDsBlock || self.identityService);
}

#pragma mark -

- (void)validateSyncLocalContactsStateForSession:(MXSession *)mxSession
{
    if (!self.allowLocalContactsAccess)
    {
        return;
    }
    
    // Get the status of the identity service terms.
    BOOL areAllTermsAgreed = mxSession.identityService.areAllTermsAgreed;
    
    if (MXKAppSettings.standardAppSettings.syncLocalContacts)
    {
        // Disable local contact sync when all terms are no longer accepted or if contacts access has been revoked.
        if (!areAllTermsAgreed || [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] != CNAuthorizationStatusAuthorized)
        {
            MXLogDebug(@"[MXKContactManager] validateSyncLocalContactsState : Disabling contacts sync.");
            MXKAppSettings.standardAppSettings.syncLocalContacts = false;
            return;
        }
    }
    else
    {
        // Check whether the user has been directed to the Settings app to enable contact access.
        if (MXKAppSettings.standardAppSettings.syncLocalContactsPermissionOpenedSystemSettings)
        {
            // Reset the system settings app flag as they are back in the app.
            MXKAppSettings.standardAppSettings.syncLocalContactsPermissionOpenedSystemSettings = false;
            
            // And if all other conditions are met for contacts sync enable it.
            if (areAllTermsAgreed && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
            {
                MXLogDebug(@"[MXKContactManager] validateSyncLocalContactsState : Enabling contacts sync after user visited Settings app.");
                MXKAppSettings.standardAppSettings.syncLocalContacts = true;
            }
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)refreshLocalContacts
{
    MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Started");
    
    if (!self.allowLocalContactsAccess)
    {
        MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Finished because local contacts access not allowed.");
        return;
    }
    
    NSDate *startDate = [NSDate date];
    
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] != CNAuthorizationStatusAuthorized)
    {
        if ([MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            // The user authorised syncLocalContacts and allowed access to his contacts
            // but he then removed contacts access from app permissions.
            // So, reset syncLocalContacts value
            [MXKAppSettings standardAppSettings].syncLocalContacts = NO;
        }
        
        // Local contacts list is empty if the access is denied.
        self->localContactByContactID = nil;
        self->localContactsWithMethods = nil;
        self->splitLocalContacts = nil;
        [self cacheLocalContacts];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactsNotification object:nil userInfo:nil];
        
        MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Complete");
        MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Local contacts access denied");
    }
    else
    {
        self->isLocalContactListRefreshing = YES;
        
        // Reset the internal contact lists (These arrays will be prepared only if need).
        self->localContactsWithMethods = self->splitLocalContacts = nil;
        
        BOOL isColdStart = NO;
        
        // Check whether the local contacts sync has been disabled.
        if (self->matrixIDBy3PID && ![MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            // The user changed his mind and disabled the local contact sync, remove the cached data.
            self->matrixIDBy3PID = nil;
            [self cacheMatrixIDsDict];
            
            // Reload the local contacts from the system
            self->localContactByContactID = nil;
            [self cacheLocalContacts];
        }
        
        // Check whether this is a cold start.
        if (!self->matrixIDBy3PID)
        {
            isColdStart = YES;
            
            // Load the dictionary from the file system. It is cached to improve UX.
            [self loadCachedMatrixIDsDict];
        }
        
        MXWeakify(self);
        
        dispatch_async(self->processingQueue, ^{
            
            MXStrongifyAndReturnIfNil(self);

            // In case of cold start, retrieve the data from the file system
            if (isColdStart)
            {
                [self loadCachedLocalContacts];
                [self loadCachedContactBookInfo];

                // no local contact -> assume that the last sync date is useless
                if (self->localContactByContactID.count == 0)
                {
                    self->lastSyncDate = nil;
                }
            }

            BOOL didContactBookChange = NO;

            NSMutableArray* deletedContactIDs = [NSMutableArray arrayWithArray:[self->localContactByContactID allKeys]];

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

                        NSString* contactID = [MXKContact contactID:contactRecord];

                        // the contact still exists
                        [deletedContactIDs removeObject:contactID];

                        if (self->lastSyncDate)
                        {
                            // ignore unchanged contacts since the previous sync
                            CFDateRef lastModifDate = ABRecordCopyValue(contactRecord, kABPersonModificationDateProperty);
                            if (lastModifDate)
                            {
                                if (kCFCompareGreaterThan != CFDateCompare(lastModifDate, (__bridge CFDateRef)self->lastSyncDate, nil))

                                {
                                    CFRelease(lastModifDate);
                                    continue;
                                }
                                CFRelease(lastModifDate);
                            }
                        }

                        didContactBookChange = YES;

                        MXKContact* contact = [[MXKContact alloc] initLocalContactWithABRecord:contactRecord];

                        if (countryCode)
                        {
                            contact.defaultCountryCode = countryCode;
                        }

                        // update the local contacts list
                        [self->localContactByContactID setValue:contact forKey:contactID];
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
                didContactBookChange = YES;
                [self->localContactByContactID removeObjectForKey:contactID];
            }

            // something has been modified in the local contact book
            if (didContactBookChange)
            {
                [self cacheLocalContacts];
            }
            
            self->lastSyncDate = [NSDate date];
            [self cacheContactBookInfo];
            
            // Update loaded contacts with the known dict 3PID -> matrix ID
            [self updateAllLocalContactsMatrixIDs];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Contacts are loaded, post a notification
                self->isLocalContactListRefreshing = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactsNotification object:nil userInfo:nil];
                
                // Check the conditions required before triggering a matrix users lookup.
                if (isColdStart || didContactBookChange)
                {
                    [self updateMatrixIDsForAllLocalContacts];
                }
                
                MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Complete");
                MXLogDebug(@"[MXKContactManager] refreshLocalContacts : Refresh %tu local contacts in %.0fms", self->localContactByContactID.count, [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
            });
        });
    }
}
#pragma clang diagnostic pop

- (void)updateMatrixIDsForLocalContact:(MXKContact *)contact
{
    // Check if the user allowed to sync local contacts.
    // + Check whether users discovering is available.
    if ([MXKAppSettings standardAppSettings].syncLocalContacts && !contact.isMatrixContact && [self isUsersDiscoveringEnabled])
    {
        // Retrieve all 3PIDs of the contact
        NSMutableArray* threepids = [[NSMutableArray alloc] init];
        NSMutableArray* lookup3pidsArray = [[NSMutableArray alloc] init];
        
        for (MXKEmail* email in contact.emailAddresses)
        {
            // Not yet added
            if (email.emailAddress.length && [threepids indexOfObject:email.emailAddress] == NSNotFound)
            {
                [lookup3pidsArray addObject:@[kMX3PIDMediumEmail, email.emailAddress]];
                [threepids addObject:email.emailAddress];
            }
        }
        
        for (MXKPhoneNumber* phone in contact.phoneNumbers)
        {
            if (phone.msisdn)
            {
                [lookup3pidsArray addObject:@[kMX3PIDMediumMSISDN, phone.msisdn]];
                [threepids addObject:phone.msisdn];
            }
        }
        
        if (lookup3pidsArray.count > 0)
        {
            MXWeakify(self);
            
            void (^success)(NSArray<NSArray<NSString *> *> *) = ^(NSArray<NSArray<NSString *> *> *discoveredUsers) {
                MXStrongifyAndReturnIfNil(self);
                
                // Look for updates
                BOOL isUpdated = NO;
                
                // Consider each discored user
                for (NSArray *discoveredUser in discoveredUsers)
                {
                    // Sanity check
                    if (discoveredUser.count == 3)
                    {
                        NSString *pid = discoveredUser[1];
                        NSString *matrixId = discoveredUser[2];
                        
                        // Remove the 3pid from the requested list
                        [threepids removeObject:pid];
                        
                        NSString *currentMatrixID = [self->matrixIDBy3PID objectForKey:pid];
                        
                        if (![currentMatrixID isEqualToString:matrixId])
                        {
                            [self->matrixIDBy3PID setObject:matrixId forKey:pid];
                            isUpdated = YES;
                        }
                    }
                }
                
                // Remove existing information which is not valid anymore
                for (NSString *pid in threepids)
                {
                    if ([self->matrixIDBy3PID objectForKey:pid])
                    {
                        [self->matrixIDBy3PID removeObjectForKey:pid];
                        isUpdated = YES;
                    }
                }
                
                if (isUpdated)
                {
                    [self cacheMatrixIDsDict];
                    
                    // Update only this contact
                    [self updateLocalContactMatrixIDs:contact];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:contact.contactID userInfo:nil];
                    });
                }
            };
            
            void (^failure)(NSError *) = ^(NSError *error) {
                MXLogDebug(@"[MXKContactManager] updateMatrixIDsForLocalContact failed");
            };
            
            if (self.discoverUsersBoundTo3PIDsBlock)
            {
                self.discoverUsersBoundTo3PIDsBlock(lookup3pidsArray, success, failure);
            }
            else
            {
                // Consider the potential identity server url by default
                [self.identityService lookup3pids:lookup3pidsArray
                                          success:success
                                          failure:failure];
            }
        }
    }
}


- (void)updateMatrixIDsForAllLocalContacts
{
    // If localContactByContactID is not loaded, the manager will consider there is no local contacts
    // and will reset its cache
    NSAssert(localContactByContactID, @"[MXKContactManager] updateMatrixIDsForAllLocalContacts: refreshLocalContacts must be called before");

    // Check if the user allowed to sync local contacts.
    // + Check if at least an identity server is available, and if the loading step is not in progress.
    if (![MXKAppSettings standardAppSettings].syncLocalContacts || ![self isUsersDiscoveringEnabled] || isLocalContactListRefreshing)
    {
        return;
    }
    
    MXWeakify(self);
    
    // Refresh the 3PIDs -> Matrix ID mapping
    dispatch_async(processingQueue, ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        NSArray* contactsSnapshot = [self->localContactByContactID allValues];
        
        // Retrieve all 3PIDs
        NSMutableArray* threepids = [[NSMutableArray alloc] init];
        NSMutableArray* lookup3pidsArray = [[NSMutableArray alloc] init];
        
        for (MXKContact* contact in contactsSnapshot)
        {
            for (MXKEmail* email in contact.emailAddresses)
            {
                // Not yet added
                if (email.emailAddress.length && [threepids indexOfObject:email.emailAddress] == NSNotFound)
                {
                    [lookup3pidsArray addObject:@[kMX3PIDMediumEmail, email.emailAddress]];
                    [threepids addObject:email.emailAddress];
                }
            }
            
            for (MXKPhoneNumber* phone in contact.phoneNumbers)
            {
                if (phone.msisdn)
                {
                    // Not yet added
                    if ([threepids indexOfObject:phone.msisdn] == NSNotFound)
                    {
                        [lookup3pidsArray addObject:@[kMX3PIDMediumMSISDN, phone.msisdn]];
                        [threepids addObject:phone.msisdn];
                    }
                }
            }
        }
        
        // Update 3PIDs mapping
        if (lookup3pidsArray.count > 0)
        {
            MXWeakify(self);
            
            void (^success)(NSArray<NSArray<NSString *> *> *) = ^(NSArray<NSArray<NSString *> *> *discoveredUsers) {
                MXStrongifyAndReturnIfNil(self);
                
                [threepids removeAllObjects];
                NSMutableArray* userIds = [[NSMutableArray alloc] init];
                
                // Consider each discored user
                for (NSArray *discoveredUser in discoveredUsers)
                {
                    // Sanity check
                    if (discoveredUser.count == 3)
                    {
                        id threepid = discoveredUser[1];
                        id userId = discoveredUser[2];
                        
                        if ([threepid isKindOfClass:[NSString class]] && [userId isKindOfClass:[NSString class]])
                        {
                            [threepids addObject:threepid];
                            [userIds addObject:userId];
                        }
                    }
                }
                
                if (userIds.count)
                {
                    self->matrixIDBy3PID = [[NSMutableDictionary alloc] initWithObjects:userIds forKeys:threepids];
                }
                else
                {
                    self->matrixIDBy3PID = nil;
                }
                
                [self cacheMatrixIDsDict];
                
                [self updateAllLocalContactsMatrixIDs];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil userInfo:nil];
                });
            };
            
            void (^failure)(NSError *) = ^(NSError *error) {
                MXLogDebug(@"[MXKContactManager] updateMatrixIDsForAllLocalContacts failed");
            };
            
            if (self.discoverUsersBoundTo3PIDsBlock)
            {
                self.discoverUsersBoundTo3PIDsBlock(lookup3pidsArray, success, failure);
            }
            else if (self.identityService)
            {
                [self.identityService lookup3pids:lookup3pidsArray
                                          success:success
                                          failure:failure];
            }
            else
            {
                // No IS, no detection of Matrix users in local contacts
                self->matrixIDBy3PID = nil;
                [self cacheMatrixIDsDict];
            }
        }
        else
        {
            self->matrixIDBy3PID = nil;
            [self cacheMatrixIDsDict];
        }
    });
}

- (void)resetMatrixIDs
{
    dispatch_async(processingQueue, ^{
        
        self->matrixIDBy3PID = nil;
        [self cacheMatrixIDsDict];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil userInfo:nil];
        });
    });
}

- (void)reset
{
    matrixIDBy3PID = nil;
    [self cacheMatrixIDsDict];
    
    isLocalContactListRefreshing = NO;
    localContactByContactID = nil;
    localContactsWithMethods = nil;
    splitLocalContacts = nil;
    [self cacheLocalContacts];
    
    matrixContactByContactID = nil;
    matrixContactByMatrixID = nil;
    [self cacheMatrixContacts];
    
    lastSyncDate = nil;
    [self cacheContactBookInfo];
    
    while (mxSessionArray.count) {
        [self removeMatrixSession:mxSessionArray.lastObject];
    }
    mxSessionArray = nil;
    mxEventListeners = nil;
    
    // warn of the contacts list update
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateLocalContactsNotification object:nil userInfo:nil];
}

- (MXKContact*)contactWithContactID:(NSString*)contactID
{
    if ([contactID hasPrefix:kMXKContactLocalContactPrefixId])
    {
        return [localContactByContactID objectForKey:contactID];
    }
    else
    {
        return [matrixContactByContactID objectForKey:contactID];
    }
}

// refresh the international phonenumber of the contacts
- (void)internationalizePhoneNumbers:(NSString*)countryCode
{
    MXWeakify(self);
    
    dispatch_async(processingQueue, ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        NSArray* contactsSnapshot = [self->localContactByContactID allValues];
        
        for (MXKContact* contact in contactsSnapshot)
        {
            contact.defaultCountryCode = countryCode;
        }
        
        [self cacheLocalContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidInternationalizeNotification object:nil userInfo:nil];
        });
    });
}

- (MXKSectionedContacts *)getSectionedContacts:(NSArray*)contactsList
{
    if (!contactsList.count)
    {
        return nil;
    }
    
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
    
    for (MXKContact *aContact in contactsList)
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
    
    return [[MXKSectionedContacts alloc] initWithContacts:shortSectionsArray andTitles:tmpSectionedContactsTitle andCount:contactsCount];
}

- (void)sortAlphabeticallyContacts:(NSMutableArray<MXKContact*> *)contactsArray
{
    NSComparator comparator = ^NSComparisonResult(MXKContact *contactA, MXKContact *contactB) {
        
        if (contactA.sortingDisplayName.length && contactB.sortingDisplayName.length)
        {
            return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
        }
        else if (contactA.sortingDisplayName.length)
        {
            return NSOrderedAscending;
        }
        else if (contactB.sortingDisplayName.length)
        {
            return NSOrderedDescending;
        }
        return [contactA.displayName compare:contactB.displayName options:NSCaseInsensitiveSearch];
    };
    
    // Sort the contacts list
    [contactsArray sortUsingComparator:comparator];
}

- (void)sortContactsByLastActiveInformation:(NSMutableArray<MXKContact*> *)contactsArray
{
    // Sort invitable contacts by last active, with "active now" first.
    // ...and then alphabetically.
    NSComparator comparator = ^NSComparisonResult(MXKContact *contactA, MXKContact *contactB) {
        
        MXUser *userA = [self firstMatrixUserOfContact:contactA];
        MXUser *userB = [self firstMatrixUserOfContact:contactB];
        
        // Non-Matrix-enabled contacts are moved to the end.
        if (userA && !userB)
        {
            return NSOrderedAscending;
        }
        if (!userA && userB)
        {
            return NSOrderedDescending;
        }
        
        // Display active contacts first.
        if (userA.currentlyActive && userB.currentlyActive)
        {
            // Then order by name
            if (contactA.sortingDisplayName.length && contactB.sortingDisplayName.length)
            {
                return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
            }
            else if (contactA.sortingDisplayName.length)
            {
                return NSOrderedAscending;
            }
            else if (contactB.sortingDisplayName.length)
            {
                return NSOrderedDescending;
            }
            return [contactA.displayName compare:contactB.displayName options:NSCaseInsensitiveSearch];
        }
        
        if (userA.currentlyActive && !userB.currentlyActive)
        {
            return NSOrderedAscending;
        }
        if (!userA.currentlyActive && userB.currentlyActive)
        {
            return NSOrderedDescending;
        }
        
        // Finally, compare the lastActiveAgo
        NSUInteger lastActiveAgoA = userA.lastActiveAgo;
        NSUInteger lastActiveAgoB = userB.lastActiveAgo;
        
        if (lastActiveAgoA == lastActiveAgoB)
        {
            return NSOrderedSame;
        }
        else
        {
            return ((lastActiveAgoA > lastActiveAgoB) ? NSOrderedDescending : NSOrderedAscending);
        }
    };
    
    // Sort the contacts list
    [contactsArray sortUsingComparator:comparator];
}

+ (void)requestUserConfirmationForLocalContactsSyncInViewController:(UIViewController *)viewController completionHandler:(void (^)(BOOL))handler
{
    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    [MXKContactManager requestUserConfirmationForLocalContactsSyncWithTitle:[VectorL10n localContactsAccessDiscoveryWarningTitle]
                                                                    message:[VectorL10n localContactsAccessDiscoveryWarning:appDisplayName]
                                                manualPermissionChangeMessage:[VectorL10n localContactsAccessNotGranted:appDisplayName]
                                                    showPopUpInViewController:viewController
                                                            completionHandler:handler];
}

+ (void)requestUserConfirmationForLocalContactsSyncWithTitle:(NSString*)title
                                                     message:(NSString*)message
                                           manualPermissionChangeMessage:(NSString*)manualPermissionChangeMessage
                                     showPopUpInViewController:(UIViewController*)viewController
                                             completionHandler:(void (^)(BOOL granted))handler
{
    if ([[MXKAppSettings standardAppSettings] syncLocalContacts])
    {
        handler(YES);
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    
                                                    [MXKTools checkAccessForContacts:manualPermissionChangeMessage showPopUpInViewController:viewController completionHandler:^(BOOL granted) {
                                                        
                                                        handler(granted);
                                                    }];
                                                    
                                                }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    
                                                    handler(NO);
                                                    
                                                }]];
        
        
        [viewController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Internals

- (NSDictionary*)matrixContactsByMatrixIDFromMXSessions:(NSArray<MXSession*>*)mxSessions
{
    // The existing dictionary of contacts will be replaced by this one
    NSMutableDictionary *matrixContactByMatrixID = [[NSMutableDictionary alloc] init];
    for (MXSession *mxSession in mxSessions)
    {
        // Check all existing users
        NSArray *mxUsers = [mxSession.users copy];
        
        for (MXUser *user in mxUsers)
        {
            // Check whether this user has already been added
            if (!matrixContactByMatrixID[user.userId])
            {
                if ((self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceAll) || ((self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceDirectChats) && mxSession.directRooms[user.userId]))
                {
                    // Check whether a contact is already defined for this id in previous dictionary
                    // (avoid delete and create the same ones, it could save thumbnail downloads).
                    MXKContact* contact = matrixContactByMatrixID[user.userId];
                    if (contact)
                    {
                        contact.displayName = (user.displayname.length > 0) ? user.displayname : user.userId;
                        
                        // Check the avatar change
                        if ((user.avatarUrl || contact.matrixAvatarURL) && ([user.avatarUrl isEqualToString:contact.matrixAvatarURL] == NO))
                        {
                            [contact resetMatrixThumbnail];
                        }
                    }
                    else
                    {
                        contact = [[MXKContact alloc] initMatrixContactWithDisplayName:((user.displayname.length > 0) ? user.displayname : user.userId) andMatrixID:user.userId];
                    }
                    
                    matrixContactByMatrixID[user.userId] = contact;
                }
            }
        }
    }
    
    // Do not make an immutable copy to avoid performance penalty
    return matrixContactByMatrixID;
}

- (void)refreshMatrixContacts
{
    NSArray *mxSessions = self.mxSessions;

    // Check whether at least one session is available
    if (!mxSessions.count)
    {
        matrixContactByMatrixID = nil;
        matrixContactByContactID = nil;
        [self cacheMatrixContacts];

        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil userInfo:nil];
    }
    else if (self.contactManagerMXRoomSource != MXKContactManagerMXRoomSourceNone)
    {
        MXWeakify(self);

        BOOL shouldFetchLocalContacts = self->matrixContactByContactID == nil;
        
        dispatch_async(processingQueue, ^{

            MXStrongifyAndReturnIfNil(self);
            
            NSArray *sessions = self.mxSessions;

            NSMutableDictionary *matrixContactsByMatrixID = nil;
            NSMutableDictionary *matrixContactsByContactID = nil;

            if (shouldFetchLocalContacts)
            {
                NSDictionary *cachedMatrixContacts = [self fetchCachedMatrixContacts];

                if (!matrixContactsByContactID)
                {
                    matrixContactsByContactID = [NSMutableDictionary dictionary];
                }
                else
                {
                    matrixContactsByContactID = [cachedMatrixContacts mutableCopy];
                }
            }
            else
            {
                matrixContactsByContactID = [NSMutableDictionary dictionary];
            }

            NSDictionary *matrixContacts = [self matrixContactsByMatrixIDFromMXSessions:sessions];

            if (!matrixContacts)
            {
                matrixContactsByMatrixID = [NSMutableDictionary dictionary];
                
                for (MXKContact *contact in matrixContactsByContactID.allValues)
                {
                    matrixContactsByMatrixID[contact.matrixIdentifiers.firstObject] = contact;
                }
            }
            else
            {
                matrixContactsByMatrixID = [matrixContacts mutableCopy];
            }

            for (MXKContact *contact in matrixContactsByMatrixID.allValues)
            {
                matrixContactsByContactID[contact.contactID] = contact;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                MXStrongifyAndReturnIfNil(self);

                // Update the matrix contacts list
                self->matrixContactByMatrixID = matrixContactsByMatrixID;
                self->matrixContactByContactID = matrixContactsByContactID;

                [self cacheMatrixContacts];

                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil userInfo:nil];
            });
        });
    }
}

- (void)updateMatrixContactWithID:(NSString*)matrixId
{
    // Check if a one-to-one room exist for this matrix user in at least one matrix session.
    NSArray *mxSessions = self.mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        if ((self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceAll) || ((self.contactManagerMXRoomSource == MXKContactManagerMXRoomSourceDirectChats) && mxSession.directRooms[matrixId]))
        {
            // Retrieve the user object related to this contact
            MXUser* user = [mxSession userWithUserId:matrixId];
            
            // This user may not exist (if the oneToOne room is a pending invitation to him).
            if (user)
            {
                // Update or create a contact for this user
                MXKContact* contact = [matrixContactByMatrixID objectForKey:matrixId];
                BOOL isUpdated = NO;
                
                // already defined
                if (contact)
                {
                    // Check the display name change
                    NSString *userDisplayName = (user.displayname.length > 0) ? user.displayname : user.userId;
                    if (![contact.displayName isEqualToString:userDisplayName])
                    {
                        contact.displayName = userDisplayName;
                        
                        [self cacheMatrixContacts];
                        isUpdated = YES;
                    }
                    
                    // Check the avatar change
                    if ((user.avatarUrl || contact.matrixAvatarURL) && ([user.avatarUrl isEqualToString:contact.matrixAvatarURL] == NO))
                    {
                        [contact resetMatrixThumbnail];
                        isUpdated = YES;
                    }
                }
                else
                {
                    contact = [[MXKContact alloc] initMatrixContactWithDisplayName:((user.displayname.length > 0) ? user.displayname : user.userId) andMatrixID:user.userId];
                    [matrixContactByMatrixID setValue:contact forKey:matrixId];
                    
                    // update the matrix contacts list
                    [matrixContactByContactID setValue:contact forKey:contact.contactID];
                    
                    [self cacheMatrixContacts];
                    isUpdated = YES;
                }
                
                if (isUpdated)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateMatrixContactsNotification object:contact.contactID userInfo:nil];
                }
                
                // Done
                return;
            }
        }
    }
    
    // Here no one-to-one room exist, remove the contact if any
    MXKContact* contact = [matrixContactByMatrixID objectForKey:matrixId];
    if (contact)
    {
        [matrixContactByContactID removeObjectForKey:contact.contactID];
        [matrixContactByMatrixID removeObjectForKey:matrixId];
        
        [self cacheMatrixContacts];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactManagerDidUpdateMatrixContactsNotification object:contact.contactID userInfo:nil];
    }
}

- (void)updateLocalContactMatrixIDs:(MXKContact*) contact
{
    for (MXKPhoneNumber* phoneNumber in contact.phoneNumbers)
    {
        if (phoneNumber.msisdn)
        {
            NSString* matrixID = [matrixIDBy3PID objectForKey:phoneNumber.msisdn];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [phoneNumber setMatrixID:matrixID];
                
            });
        }
    }
    
    for (MXKEmail* email in contact.emailAddresses)
    {
        if (email.emailAddress.length > 0)
        {
            NSString *matrixID = [matrixIDBy3PID objectForKey:email.emailAddress];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [email setMatrixID:matrixID];
                
            });
        }
    }
}

- (void)updateAllLocalContactsMatrixIDs
{
    // Check if the user allowed to sync local contacts
    if (![MXKAppSettings standardAppSettings].syncLocalContacts)
    {
        return;
    }
    
    NSArray* localContacts = [localContactByContactID allValues];
    
    // update the contacts info
    for (MXKContact* contact in localContacts)
    {
        [self updateLocalContactMatrixIDs:contact];
    }
}

- (MXUser*)firstMatrixUserOfContact:(MXKContact*)contact;
{
    MXUser *user = nil;
    
    NSArray *identifiers = contact.matrixIdentifiers;
    if (identifiers.count)
    {
        for (MXSession *session in mxSessionArray)
        {
            user = [session userWithUserId:identifiers.firstObject];
            if (user)
            {
                break;
            }
        }
    }
    
    return user;
}


#pragma mark - Identity server updates

- (void)registerAccountDataDidChangeIdentityServerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountDataDidChangeIdentityServerNotification:) name:kMXSessionAccountDataDidChangeIdentityServerNotification object:nil];
}

- (void)handleAccountDataDidChangeIdentityServerNotification:(NSNotification*)notification
{
    MXLogDebug(@"[MXKContactManager] handleAccountDataDidChangeIdentityServerNotification");
    
    if (!self.allowLocalContactsAccess)
    {
        MXLogDebug(@"[MXKContactManager] handleAccountDataDidChangeIdentityServerNotification. Does nothing because local contacts access not allowed.");
        return;
    }

    // Use the identity server of the up
    MXSession *mxSession = notification.object;
    if (mxSession != mxSessionArray.firstObject)
    {
        return;
    }

    if (self.identityService)
    {
        // Do a full lookup
        // But check first if the data is loaded
        if (!self->localContactByContactID )
        {
            // Load data. That will trigger updateMatrixIDsForAllLocalContacts if needed
            [self refreshLocalContacts];
        }
        else
        {
            [self updateMatrixIDsForAllLocalContacts];
        }
    }
    else
    {
        [self resetMatrixIDs];
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (!self.allowLocalContactsAccess)
    {
        MXLogDebug(@"[MXKContactManager] Ignoring KVO changes, because local contacts access not allowed.");
        return;
    }
    
    if ([@"syncLocalContacts" isEqualToString:keyPath])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self refreshLocalContacts];
            
        });
    }
    else if ([@"phonebookCountryCode" isEqualToString:keyPath])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self internationalizePhoneNumbers:[[MXKAppSettings standardAppSettings] phonebookCountryCode]];
            
            // Refresh local contacts if we have some
            if (MXKAppSettings.standardAppSettings.syncLocalContacts && self->localContactByContactID.count)
            {
                [self refreshLocalContacts];
            }
            
        });
    }
}

#pragma mark - file caches

static NSString *MXKContactManagerDomain = @"org.matrix.MatrixKit.MXKContactManager";
static NSInteger MXContactManagerEncryptionDelegateNotReady = -1;

static NSString *matrixContactsFileOld = @"matrixContacts";
static NSString *matrixIDsDictFileOld = @"matrixIDsDict";
static NSString *localContactsFileOld = @"localContacts";
static NSString *contactsBookInfoFileOld = @"contacts";

static NSString *matrixContactsFile = @"matrixContactsV2";
static NSString *matrixIDsDictFile = @"matrixIDsDictV2";
static NSString *localContactsFile = @"localContactsV2";
static NSString *contactsBookInfoFile = @"contactsV2";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSString*)dataFilePathForComponent:(NSString*)component
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:component];
}

- (void)cacheMatrixContacts
{
    NSString *dataFilePath = [self dataFilePathForComponent:matrixContactsFile];
    
    if (matrixContactByContactID && (matrixContactByContactID.count > 0))
    {
        // Switch on processing queue because matrixContactByContactID dictionary may be huge.
        NSDictionary *matrixContactByContactIDCpy = [matrixContactByContactID copy];
        
        dispatch_async(processingQueue, ^{
            
            NSMutableData *theData = [NSMutableData data];
            NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
            
            [encoder encodeObject:matrixContactByContactIDCpy forKey:@"matrixContactByContactID"];
            
            [encoder finishEncoding];
            
            [self encryptAndSaveData:theData toFile:matrixContactsFile];
        });
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (NSDictionary*)fetchCachedMatrixContacts
{
    NSDate *startDate = [NSDate date];
    
    NSString *dataFilePath = [self dataFilePathForComponent:matrixContactsFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    __block NSDictionary *matrixContactByContactID = nil;
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSError *error = nil;
            filecontent = [self decryptData:filecontent error:&error fileName:matrixContactsFile];

            if (!error)
            {
                NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
                
                id object = [decoder decodeObjectForKey:@"matrixContactByContactID"];
                
                if ([object isKindOfClass:[NSDictionary class]])
                {
                    matrixContactByContactID = object;
                }
                
                [decoder finishDecoding];
            }
            else
            {
                MXLogDebug(@"[MXKContactManager] fetchCachedMatrixContacts: failed to decrypt %@: %@", matrixContactsFile, error);
            }
        }
        @catch (NSException *exception)
        {
        }
    }
    
    MXLogDebug(@"[MXKContactManager] fetchCachedMatrixContacts : Loaded %tu contacts in %.0fms", matrixContactByContactID.count, [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
    
    return matrixContactByContactID;
}

- (void)cacheMatrixIDsDict
{
    NSString *dataFilePath = [self dataFilePathForComponent:matrixIDsDictFile];
    
    if (matrixIDBy3PID.count)
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:matrixIDBy3PID forKey:@"matrixIDsDict"];
        [encoder finishEncoding];
        
        [self encryptAndSaveData:theData toFile:matrixIDsDictFile];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void)loadCachedMatrixIDsDict
{
    NSString *dataFilePath = [self dataFilePathForComponent:matrixIDsDictFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSError *error = nil;
            filecontent = [self decryptData:filecontent error:&error fileName:matrixIDsDictFile];

            if (!error)
            {
                NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
                
                id object = [decoder decodeObjectForKey:@"matrixIDsDict"];
                
                if ([object isKindOfClass:[NSDictionary class]])
                {
                    matrixIDBy3PID = [object mutableCopy];
                }
                
                [decoder finishDecoding];
            }
            else
            {
                MXLogDebug(@"[MXKContactManager] loadCachedMatrixIDsDict: failed to decrypt %@: %@", matrixIDsDictFile, error);
            }
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

- (void)cacheLocalContacts
{
    NSString *dataFilePath = [self dataFilePathForComponent:localContactsFile];
    
    if (localContactByContactID && (localContactByContactID.count > 0))
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:localContactByContactID forKey:@"localContactByContactID"];
        
        [encoder finishEncoding];
        
        [self encryptAndSaveData:theData toFile:localContactsFile];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void)loadCachedLocalContacts
{
    NSString *dataFilePath = [self dataFilePathForComponent:localContactsFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSError *error = nil;
            filecontent = [self decryptData:filecontent error:&error fileName:localContactsFile];

            if (!error)
            {
                NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
                
                id object = [decoder decodeObjectForKey:@"localContactByContactID"];
                
                if ([object isKindOfClass:[NSDictionary class]])
                {
                    localContactByContactID = [object mutableCopy];
                }
                
                [decoder finishDecoding];
            }
            else
            {
                MXLogDebug(@"[MXKContactManager] loadCachedLocalContacts: failed to decrypt %@: %@", localContactsFile, error);
            }
        }
        @catch (NSException *exception)
        {
            lastSyncDate = nil;
        }
    }
    
    if (!localContactByContactID)
    {
        localContactByContactID = [[NSMutableDictionary alloc] init];
    }
}

- (void)cacheContactBookInfo
{
    NSString *dataFilePath = [self dataFilePathForComponent:contactsBookInfoFile];
    
    if (lastSyncDate)
    {
        NSMutableData *theData = [NSMutableData data];
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:theData];
        
        [encoder encodeObject:lastSyncDate forKey:@"lastSyncDate"];
        
        [encoder finishEncoding];
        
        [self encryptAndSaveData:theData toFile:contactsBookInfoFile];
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:dataFilePath error:nil];
    }
}

- (void)loadCachedContactBookInfo
{
    NSString *dataFilePath = [self dataFilePathForComponent:contactsBookInfoFile];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:dataFilePath])
    {
        // the file content could be corrupted
        @try
        {
            NSData* filecontent = [NSData dataWithContentsOfFile:dataFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            
            NSError *error = nil;
            filecontent = [self decryptData:filecontent error:&error fileName:contactsBookInfoFile];

            if (!error)
            {
                NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:filecontent];
                
                lastSyncDate = [decoder decodeObjectForKey:@"lastSyncDate"];
                
                [decoder finishDecoding];
            }
            else
            {
                lastSyncDate = nil;
                MXLogDebug(@"[MXKContactManager] loadCachedContactBookInfo: failed to decrypt %@: %@", contactsBookInfoFile, error);
            }
        }
        @catch (NSException *exception)
        {
            lastSyncDate = nil;
        }
    }
}

#pragma clang diagnostic pop

- (BOOL)encryptAndSaveData:(NSData*)data toFile:(NSString*)fileName
{
    NSError *error = nil;
    NSData *cipher = [self encryptData:data error:&error fileName:fileName];

    if (error == nil)
    {
        [cipher writeToFile:[self dataFilePathForComponent:fileName] atomically:YES];
        [[NSFileManager defaultManager] excludeItemFromBackupAt:[NSURL fileURLWithPath:fileName] error:&error];
        if (error) {
            MXLogDebug(@"[MXKContactManager] Cannot exclude item from backup %@", error.localizedDescription);
        }
    }
    else
    {
        MXLogDebug(@"[MXKContactManager] encryptAndSaveData: failed to encrypt %@", fileName);
    }
    
    return error == nil;
}

- (NSData*)encryptData:(NSData*)data error:(NSError**)error fileName:(NSString*)fileName
{
    @try
    {
        MXKeyData *keyData = (MXKeyData *) [[MXKeyProvider sharedInstance] requestKeyForDataOfType:MXKContactManagerDataType isMandatory:NO expectedKeyType:kAes];
        if (keyData && [keyData isKindOfClass:[MXAesKeyData class]])
        {
            MXAesKeyData *aesKey = (MXAesKeyData *) keyData;
            NSData *cipher = [MXAes encrypt:data aesKey:aesKey.key iv:aesKey.iv error:error];
            MXLogDebug(@"[MXKContactManager] encryptData: encrypted %lu Bytes for %@", cipher.length, fileName);
            return cipher;
        }
    }
    @catch (NSException *exception)
    {
        *error = [NSError errorWithDomain:MXKContactManagerDomain code:MXContactManagerEncryptionDelegateNotReady userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"encryptData failed: %@", exception.reason]}];
    }
    
    MXLogDebug(@"[MXKContactManager] encryptData: no key method provided for encryption of %@", fileName);
    return data;
}

- (NSData*)decryptData:(NSData*)data error:(NSError**)error fileName:(NSString*)fileName
{
    @try
    {
        MXKeyData *keyData = [[MXKeyProvider sharedInstance] requestKeyForDataOfType:MXKContactManagerDataType isMandatory:NO expectedKeyType:kAes];
        if (keyData && [keyData isKindOfClass:[MXAesKeyData class]])
        {
            MXAesKeyData *aesKey = (MXAesKeyData *) keyData;
            NSData *decrypt = [MXAes decrypt:data aesKey:aesKey.key iv:aesKey.iv error:error];
            MXLogDebug(@"[MXKContactManager] decryptData: decrypted %lu Bytes for %@", decrypt.length, fileName);
            return decrypt;
        }
    }
    @catch (NSException *exception)
    {
        *error = [NSError errorWithDomain:MXKContactManagerDomain code:MXContactManagerEncryptionDelegateNotReady userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"decryptData failed: %@", exception.reason]}];
    }
    
    MXLogDebug(@"[MXKContactManager] decryptData: no key method provided for decryption of %@", fileName);
    return data;
}

- (void)deleteOldFiles {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray<NSString*> *oldFileNames = @[matrixContactsFileOld, matrixIDsDictFileOld, localContactsFileOld, contactsBookInfoFileOld];
    NSError *error = nil;
    
    for (NSString *fileName in oldFileNames) {
        NSString *filePath = [self dataFilePathForComponent:fileName];
        if ([fileManager fileExistsAtPath:filePath])
        {
            error = nil;
            if (![fileManager removeItemAtPath:filePath error:&error])
            {
                MXLogDebug(@"[MXKContactManager] deleteOldFiles: failed to remove %@", fileName);
            }
        }
    }
}

@end
