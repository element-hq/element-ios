/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAppSettings.h"

#import "MXKTools.h"
@import MatrixSDK;


// get ISO country name
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

static MXKAppSettings *standardAppSettings = nil;

static NSString *const kMXAppGroupID = @"group.org.matrix";

@interface MXKAppSettings ()
{
    NSMutableArray <NSString*> *eventsFilterForMessages;
    NSMutableArray <NSString*> *allEventTypesForMessages;
    NSMutableArray <NSString*> *lastMessageEventTypesAllowList;
}

@property (nonatomic, readwrite) NSUserDefaults *sharedUserDefaults;
@property (nonatomic) NSString *currentApplicationGroup;

@end

@implementation MXKAppSettings
@synthesize syncWithLazyLoadOfRoomMembers;
@synthesize showAllEventsInRoomHistory, showRedactionsInRoomHistory, showUnsupportedEventsInRoomHistory, httpLinkScheme, httpsLinkScheme;
@synthesize enableBubbleComponentLinkDetection, firstURLDetectionIgnoredHosts, showLeftMembersInRoomMemberList, sortRoomMembersUsingLastSeenTime;
@synthesize syncLocalContacts, syncLocalContactsPermissionRequested, syncLocalContactsPermissionOpenedSystemSettings, phonebookCountryCode;
@synthesize presenceColorForOnlineUser, presenceColorForUnavailableUser, presenceColorForOfflineUser;
@synthesize enableCallKit;
@synthesize sharedUserDefaults;

+ (MXKAppSettings *)standardAppSettings
{
    @synchronized(self)
    {
        if(standardAppSettings == nil)
        {
            standardAppSettings = [[super allocWithZone:NULL] init];
        }
    }
    return standardAppSettings;
}

+ (NSString *)cacheFolder
{
    NSString *cacheFolder;

    // Check for a potential application group container
    NSURL *sharedContainerURL = [[NSFileManager defaultManager] applicationGroupContainerURL];
    if (sharedContainerURL)
    {
        cacheFolder = [sharedContainerURL path];
    }
    else
    {
        NSArray *cacheDirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cacheFolder  = [cacheDirList objectAtIndex:0];
    }

    // Use a dedicated cache folder for MatrixKit
    cacheFolder = [cacheFolder stringByAppendingPathComponent:@"MatrixKit"];

    // Make sure the folder exists so that it can be used
    if (cacheFolder && ![[NSFileManager defaultManager] fileExistsAtPath:cacheFolder])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryExcludedFromBackupAtPath:cacheFolder error:&error];
        if (error)
        {
            MXLogDebug(@"[MXKAppSettings] cacheFolder: Error: Cannot create MatrixKit folder at %@. Error: %@", cacheFolder, error);
        }
    }

    return cacheFolder;
}

#pragma  mark -

-(instancetype)init
{
    if (self = [super init])
    {
        syncWithLazyLoadOfRoomMembers = YES;

        // Use presence to sort room members by default
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"sortRoomMembersUsingLastSeenTime"])
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"sortRoomMembersUsingLastSeenTime"];
        }
        _hidePreJoinedUndecryptableEvents = NO;
        _hideUndecryptableEvents = NO;
        sortRoomMembersUsingLastSeenTime = YES;
        
        presenceColorForOnlineUser = [UIColor greenColor];
        presenceColorForUnavailableUser = [UIColor yellowColor];
        presenceColorForOfflineUser = [UIColor redColor];

        httpLinkScheme = @"http";
        httpsLinkScheme = @"https";
        enableBubbleComponentLinkDetection = NO;
        firstURLDetectionIgnoredHosts = @[[NSURL URLWithString:kMXMatrixDotToUrl].host];
        
        _allowPushKitPushers = NO;
        _notificationBodyLocalizationKey = @"MESSAGE";
        enableCallKit = YES;
        
        eventsFilterForMessages = @[
            kMXEventTypeStringRoomCreate,
            kMXEventTypeStringRoomName,
            kMXEventTypeStringRoomTopic,
            kMXEventTypeStringRoomMember,
            kMXEventTypeStringRoomEncrypted,
            kMXEventTypeStringRoomEncryption,
            kMXEventTypeStringRoomHistoryVisibility,
            kMXEventTypeStringRoomMessage,
            kMXEventTypeStringRoomThirdPartyInvite,
            kMXEventTypeStringRoomGuestAccess,
            kMXEventTypeStringRoomJoinRules,
            kMXEventTypeStringCallInvite,
            kMXEventTypeStringCallAnswer,
            kMXEventTypeStringCallHangup,
            kMXEventTypeStringCallReject,
            kMXEventTypeStringCallNegotiate,
            kMXEventTypeStringSticker,
            kMXEventTypeStringKeyVerificationCancel,
            kMXEventTypeStringKeyVerificationDone,
            kMXEventTypeStringPollStart,
            kMXEventTypeStringPollStartMSC3381,
            kMXEventTypeStringPollEnd,
            kMXEventTypeStringPollEndMSC3381,
            kMXEventTypeStringBeaconInfo,
            kMXEventTypeStringBeaconInfoMSC3672
        ].mutableCopy;
        

        // List all the event types, except kMXEventTypeStringPresence which are not related to a specific room.
        allEventTypesForMessages = @[
            kMXEventTypeStringRoomName,
            kMXEventTypeStringRoomTopic,
            kMXEventTypeStringRoomMember,
            kMXEventTypeStringRoomCreate,
            kMXEventTypeStringRoomEncrypted,
            kMXEventTypeStringRoomEncryption,
            kMXEventTypeStringRoomJoinRules,
            kMXEventTypeStringRoomPowerLevels,
            kMXEventTypeStringRoomAliases,
            kMXEventTypeStringRoomHistoryVisibility,
            kMXEventTypeStringRoomMessage,
            kMXEventTypeStringRoomMessageFeedback,
            kMXEventTypeStringRoomRedaction,
            kMXEventTypeStringRoomThirdPartyInvite,
            kMXEventTypeStringReaction,
            kMXEventTypeStringCallInvite,
            kMXEventTypeStringCallAnswer,
            kMXEventTypeStringCallSelectAnswer,
            kMXEventTypeStringCallHangup,
            kMXEventTypeStringCallReject,
            kMXEventTypeStringCallNegotiate,
            kMXEventTypeStringCallNotify,
            kMXEventTypeStringCallNotifyUnstable,
            kMXEventTypeStringSticker,
            kMXEventTypeStringKeyVerificationCancel,
            kMXEventTypeStringKeyVerificationDone,
            kMXEventTypeStringPollStart,
            kMXEventTypeStringPollStartMSC3381,
            kMXEventTypeStringPollEnd,
            kMXEventTypeStringPollEndMSC3381,
            kMXEventTypeStringBeaconInfo,
            kMXEventTypeStringBeaconInfoMSC3672
        ].mutableCopy;
        
        lastMessageEventTypesAllowList = @[
            kMXEventTypeStringRoomCreate,       // Without any messages, calls or stickers an event is needed to provide a date.
            kMXEventTypeStringRoomEncrypted,    // Show a UTD string rather than the previous message.
            kMXEventTypeStringRoomMessage,
            kMXEventTypeStringRoomMember,
            kMXEventTypeStringCallInvite,
            kMXEventTypeStringCallAnswer,
            kMXEventTypeStringCallHangup,
            kMXEventTypeStringSticker,
            kMXEventTypeStringPollStart,
            kMXEventTypeStringPollStartMSC3381,
            kMXEventTypeStringPollEnd,
            kMXEventTypeStringPollEndMSC3381
        ].mutableCopy;
        
        _messageDetailsAllowSharing = YES;
        _messageDetailsAllowSaving = YES;
        _messageDetailsAllowCopyingMedia = YES;
        _messageDetailsAllowPastingMedia = YES;
        _outboundGroupSessionKeyPreSharingStrategy = MXKKeyPreSharingWhenTyping;
    }
    return self;
}

- (void)reset
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        // Flush shared user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"syncWithLazyLoadOfRoomMembers2"];

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"showAllEventsInRoomHistory"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"showRedactionsInRoomHistory"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"showUnsupportedEventsInRoomHistory"];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sortRoomMembersUsingLastSeenTime"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"showLeftMembersInRoomMemberList"];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"syncLocalContactsPermissionRequested"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"syncLocalContacts"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"phonebookCountryCode"];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForOnlineUser"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForUnavailableUser"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForOfflineUser"];

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"httpLinkScheme"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"httpsLinkScheme"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"enableBubbleComponentLinkDetection"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"firstURLDetectionIgnoredHosts"];
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"enableCallKit"];
	}
    else
    {
        syncWithLazyLoadOfRoomMembers = YES;

        showAllEventsInRoomHistory = NO;
        showRedactionsInRoomHistory = NO;
        showUnsupportedEventsInRoomHistory = NO;
        
        sortRoomMembersUsingLastSeenTime = YES;
        showLeftMembersInRoomMemberList = NO;
        
        syncLocalContactsPermissionRequested = NO;
        syncLocalContacts = NO;
        phonebookCountryCode = nil;
        
        presenceColorForOnlineUser = [UIColor greenColor];
        presenceColorForUnavailableUser = [UIColor yellowColor];
        presenceColorForOfflineUser = [UIColor redColor];

        httpLinkScheme = @"http";
        httpsLinkScheme = @"https";
        
        enableCallKit = YES;
    }
}

- (NSUserDefaults *)sharedUserDefaults
{
    if (sharedUserDefaults)
    {
        // Check whether the current group id did not change.
        NSString *applicationGroup = [MXSDKOptions sharedInstance].applicationGroupIdentifier;
        if (!applicationGroup.length)
        {
            applicationGroup = kMXAppGroupID;
        }
        
        if (![_currentApplicationGroup isEqualToString:applicationGroup])
        {
            // Reset the existing shared object
            sharedUserDefaults = nil;
        }
    }
    
    if (!sharedUserDefaults)
    {
        _currentApplicationGroup = [MXSDKOptions sharedInstance].applicationGroupIdentifier;
        if (!_currentApplicationGroup.length)
        {
            _currentApplicationGroup = kMXAppGroupID;
        }
        
        sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:_currentApplicationGroup];
    }
    
    return sharedUserDefaults;
}

#pragma mark - Calls

- (BOOL)syncWithLazyLoadOfRoomMembers
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncWithLazyLoadOfRoomMembers2"];
        if (storedValue)
        {
            return [(NSNumber *)storedValue boolValue];
        }
        else
        {
            // Enabled by default
            return YES;
        }
    }
    else
    {
        return syncWithLazyLoadOfRoomMembers;
    }
}

- (void)setSyncWithLazyLoadOfRoomMembers:(BOOL)syncWithLazyLoadOfRoomMembers
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:syncWithLazyLoadOfRoomMembers forKey:@"syncWithLazyLoadOfRoomMembers2"];
    }
    else
    {
        syncWithLazyLoadOfRoomMembers = syncWithLazyLoadOfRoomMembers;
    }
}

#pragma mark - Room display

- (BOOL)showAllEventsInRoomHistory
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"showAllEventsInRoomHistory"];
    }
    else
    {
        return showAllEventsInRoomHistory;
    }
}

- (void)setShowAllEventsInRoomHistory:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"showAllEventsInRoomHistory"];
    }
    else
    {
        showAllEventsInRoomHistory = boolValue;
    }
}

- (NSArray *)eventsFilterForMessages
{
    if (showAllEventsInRoomHistory)
    {
        // Consider all the event types
        return self.allEventTypesForMessages;
    }
    else
    {
        // Display only a subset of events
        return eventsFilterForMessages;
    }
}

- (NSArray *)allEventTypesForMessages
{
    return allEventTypesForMessages;
}

- (NSArray<MXEventTypeString> *)lastMessageEventTypesAllowList
{
    return lastMessageEventTypesAllowList;
}

- (void)addSupportedEventTypes:(NSArray<NSString *> *)eventTypes
{
    [eventsFilterForMessages addObjectsFromArray:eventTypes];
    [allEventTypesForMessages addObjectsFromArray:eventTypes];
}

- (void)removeSupportedEventTypes:(NSArray<NSString *> *)eventTypes
{
    [eventsFilterForMessages removeObjectsInArray:eventTypes];
    [allEventTypesForMessages removeObjectsInArray:eventTypes];
    [lastMessageEventTypesAllowList removeObjectsInArray:eventTypes];
}

- (BOOL)showRedactionsInRoomHistory
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"showRedactionsInRoomHistory"];
    }
    else
    {
        return showRedactionsInRoomHistory;
    }
}

- (void)setShowRedactionsInRoomHistory:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"showRedactionsInRoomHistory"];
    }
    else
    {
        showRedactionsInRoomHistory = boolValue;
    }
}

- (BOOL)showUnsupportedEventsInRoomHistory
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"showUnsupportedEventsInRoomHistory"];
    }
    else
    {
        return showUnsupportedEventsInRoomHistory;
    }
}

- (void)setShowUnsupportedEventsInRoomHistory:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"showUnsupportedEventsInRoomHistory"];
    }
    else
    {
        showUnsupportedEventsInRoomHistory = boolValue;
    }
}

- (NSString *)httpLinkScheme
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        NSString *ret = [[NSUserDefaults standardUserDefaults] stringForKey:@"httpLinkScheme"];
        if (ret == nil) {
            ret = @"http";
        }
        return ret;
    }
    else
    {
        return httpLinkScheme;
    }
}

- (void)setHttpLinkScheme:(NSString *)stringValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setObject:stringValue forKey:@"httpLinkScheme"];
    }
    else
    {
        httpLinkScheme = stringValue;
    }
}

- (NSString *)httpsLinkScheme
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        NSString *ret = [[NSUserDefaults standardUserDefaults] stringForKey:@"httpsLinkScheme"];
        if (ret == nil) {
            ret = @"https";
        }
        return ret;
    }
    else
    {
        return httpsLinkScheme;
    }
}

- (void)setHttpsLinkScheme:(NSString *)stringValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setObject:stringValue forKey:@"httpsLinkScheme"];
    }
    else
    {
        httpsLinkScheme = stringValue;
    }
}

- (BOOL)enableBubbleComponentLinkDetection
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [NSUserDefaults.standardUserDefaults boolForKey:@"enableBubbleComponentLinkDetection"];
    }
    else
    {
        return enableBubbleComponentLinkDetection;
    }
}

- (void)setEnableBubbleComponentLinkDetection:(BOOL)storeLinksInBubbleComponents
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [NSUserDefaults.standardUserDefaults setBool:storeLinksInBubbleComponents forKey:@"enableBubbleComponentLinkDetection"];
    }
    else
    {
        enableBubbleComponentLinkDetection = storeLinksInBubbleComponents;
    }
}

- (NSArray<NSString *> *)firstURLDetectionIgnoredHosts
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [NSUserDefaults.standardUserDefaults objectForKey:@"firstURLDetectionIgnoredHosts"] ?: @[[NSURL URLWithString:kMXMatrixDotToUrl].host];
    }
    else
    {
        return firstURLDetectionIgnoredHosts;
    }
}

- (void)setFirstURLDetectionIgnoredHosts:(NSArray<NSString *> *)ignoredHosts
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        if (ignoredHosts == nil)
        {
            ignoredHosts = @[];
        }
        
        [NSUserDefaults.standardUserDefaults setObject:ignoredHosts forKey:@"firstURLDetectionIgnoredHosts"];
    }
    else
    {
        firstURLDetectionIgnoredHosts = ignoredHosts;
    }
}

#pragma mark - Room members

- (BOOL)sortRoomMembersUsingLastSeenTime
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"sortRoomMembersUsingLastSeenTime"];
    }
    else
    {
        return sortRoomMembersUsingLastSeenTime;
    }
}

- (void)setSortRoomMembersUsingLastSeenTime:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"sortRoomMembersUsingLastSeenTime"];
    }
    else
    {
        sortRoomMembersUsingLastSeenTime = boolValue;
    }
}

- (BOOL)showLeftMembersInRoomMemberList
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"showLeftMembersInRoomMemberList"];
    }
    else
    {
        return showLeftMembersInRoomMemberList;
    }
}

- (void)setShowLeftMembersInRoomMemberList:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"showLeftMembersInRoomMemberList"];
    }
    else
    {
        showLeftMembersInRoomMemberList = boolValue;
    }
}

#pragma mark - Contacts

- (BOOL)syncLocalContacts
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"syncLocalContacts"];
    }
    else
    {
        return syncLocalContacts;
    }
}

- (void)setSyncLocalContacts:(BOOL)boolValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:@"syncLocalContacts"];
    }
    else
    {
        syncLocalContacts = boolValue;
    }
}

- (BOOL)syncLocalContactsPermissionRequested
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"syncLocalContactsPermissionRequested"];
    }
    else
    {
        return syncLocalContactsPermissionRequested;
    }
}

- (void)setSyncLocalContactsPermissionRequested:(BOOL)theSyncLocalContactsPermissionRequested
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:theSyncLocalContactsPermissionRequested forKey:@"syncLocalContactsPermissionRequested"];
    }
    else
    {
        syncLocalContactsPermissionRequested = theSyncLocalContactsPermissionRequested;
    }
}

- (BOOL)syncLocalContactsPermissionOpenedSystemSettings
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        return [[NSUserDefaults standardUserDefaults] boolForKey:@"syncLocalContactsPermissionOpenedSystemSettings"];
    }
    else
    {
        return syncLocalContactsPermissionOpenedSystemSettings;
    }
}

- (void)setSyncLocalContactsPermissionOpenedSystemSettings:(BOOL)theSyncLocalContactsPermissionOpenedSystemSettings
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:theSyncLocalContactsPermissionOpenedSystemSettings forKey:@"syncLocalContactsPermissionOpenedSystemSettings"];
    }
    else
    {
        syncLocalContactsPermissionOpenedSystemSettings = theSyncLocalContactsPermissionOpenedSystemSettings;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (NSString*)phonebookCountryCode
{
    NSString* res = phonebookCountryCode;
    
    if (self == [MXKAppSettings standardAppSettings])
    {
        res = [[NSUserDefaults standardUserDefaults] stringForKey:@"phonebookCountryCode"];
    }
    
    // does not exist : try to get the SIM card information
    if (!res)
    {
        // get the current MCC
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        
        if (carrier)
        {
            res = [[carrier isoCountryCode] uppercaseString];
            
            if (res)
            {
                [self setPhonebookCountryCode:res];
            }
        }
    }
    
    return res;
}
#pragma clang diagnostic pop

- (void)setPhonebookCountryCode:(NSString *)stringValue
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setObject:stringValue forKey:@"phonebookCountryCode"];
    }
    else
    {
        phonebookCountryCode = stringValue;
    }
}

#pragma mark - Matrix users

- (UIColor*)presenceColorForOnlineUser
{
    UIColor *color = presenceColorForOnlineUser;
    
    if (self == [MXKAppSettings standardAppSettings])
    {
        NSNumber *rgbValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"presenceColorForOnlineUser"];
        if (rgbValue)
        {
            color = [MXKTools colorWithRGBValue:[rgbValue unsignedIntegerValue]];
        }
        else
        {
            color = [UIColor greenColor];
        }
    }
    
    return color;
}

- (void)setPresenceColorForOnlineUser:(UIColor*)color
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        if (color)
        {
            NSUInteger rgbValue = [MXKTools rgbValueWithColor:color];
            [[NSUserDefaults standardUserDefaults] setInteger:rgbValue forKey:@"presenceColorForOnlineUser"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForOnlineUser"];
        }
    }
    else
    {
        presenceColorForOnlineUser = color ? color : [UIColor greenColor];
    }
}

- (UIColor*)presenceColorForUnavailableUser
{
    UIColor *color = presenceColorForUnavailableUser;
    
    if (self == [MXKAppSettings standardAppSettings])
    {
        NSNumber *rgbValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"presenceColorForUnavailableUser"];
        if (rgbValue)
        {
            color = [MXKTools colorWithRGBValue:[rgbValue unsignedIntegerValue]];
        }
        else
        {
            color = [UIColor yellowColor];
        }
    }
    
    return color;
}

- (void)setPresenceColorForUnavailableUser:(UIColor*)color
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        if (color)
        {
            NSUInteger rgbValue = [MXKTools rgbValueWithColor:color];
            [[NSUserDefaults standardUserDefaults] setInteger:rgbValue forKey:@"presenceColorForUnavailableUser"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForUnavailableUser"];
        }
    }
    else
    {
        presenceColorForUnavailableUser = color ? color : [UIColor yellowColor];
    }
}

- (UIColor*)presenceColorForOfflineUser
{
    UIColor *color = presenceColorForOfflineUser;
    
    if (self == [MXKAppSettings standardAppSettings])
    {
        NSNumber *rgbValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"presenceColorForOfflineUser"];
        if (rgbValue)
        {
            color = [MXKTools colorWithRGBValue:[rgbValue unsignedIntegerValue]];
        }
        else
        {
            color = [UIColor redColor];
        }
    }
    
    return color;
}

- (void)setPresenceColorForOfflineUser:(UIColor *)color
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        if (color)
        {
            NSUInteger rgbValue = [MXKTools rgbValueWithColor:color];
            [[NSUserDefaults standardUserDefaults] setInteger:rgbValue forKey:@"presenceColorForOfflineUser"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"presenceColorForOfflineUser"];
        }
    }
    else
    {
        presenceColorForOfflineUser = color ? color : [UIColor redColor];
    }
}

#pragma mark - Calls

- (BOOL)isCallKitEnabled
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"enableCallKit"];
        if (storedValue)
        {
            return [(NSNumber *)storedValue boolValue];
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return enableCallKit;
    }
}

- (void)setEnableCallKit:(BOOL)enable
{
    if (self == [MXKAppSettings standardAppSettings])
    {
        [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"enableCallKit"];
    }
    else
    {
        enableCallKit = enable;
    }
}

@end
