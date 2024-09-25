/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2018 New Vector Ltd
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAccount.h"

#import "MXKAccountManager.h"
#import "MXKRoomDataSourceManager.h"
#import "MXKEventFormatter.h"

#import "MXKTools.h"
#import "MXKContactManager.h"

#import "MXKConstants.h"

#import "NSBundle+MatrixKit.h"

#import <AFNetworking/AFNetworking.h>

#import <MatrixSDK/MXBackgroundModeHandler.h>

#import "MXKSwiftHeader.h"

#import "GeneratedInterface-Swift.h"

NSString *const kMXKAccountUserInfoDidChangeNotification = @"kMXKAccountUserInfoDidChangeNotification";
NSString *const kMXKAccountAPNSActivityDidChangeNotification = @"kMXKAccountAPNSActivityDidChangeNotification";
NSString *const kMXKAccountPushKitActivityDidChangeNotification = @"kMXKAccountPushKitActivityDidChangeNotification";

NSString *const kMXKAccountErrorDomain = @"kMXKAccountErrorDomain";

static MXKAccountOnCertificateChange _onCertificateChangeBlock;
/**
 HTTP status codes for error cases on initial sync requests, for which errors will not be propagated to the client.
 */
static NSArray<NSNumber*> *initialSyncSilentErrorsHTTPStatusCodes;

@interface MXKAccount ()
{
    // We will notify user only once on session failure
    BOOL notifyOpenSessionFailure;
    
    // Reachability observer
    id reachabilityObserver;
    
    // Session state observer
    id sessionStateObserver;
    
    // Handle user's settings change
    id userUpdateListener;
    
    // Used for logging application start up
    NSDate *openSessionStartDate;
    
    // Event notifications listener
    id notificationCenterListener;
    
    // Internal list of ignored rooms
    NSMutableArray* ignoredRooms;

    // Background sync management
    MXOnBackgroundSyncDone backgroundSyncDone;
    MXOnBackgroundSyncFail backgroundSyncFails;
    NSTimer* backgroundSyncTimer;

    // Observe UIApplicationSignificantTimeChangeNotification to refresh MXRoomSummaries on time formatting change.
    id UIApplicationSignificantTimeChangeNotificationObserver;

    // Observe NSCurrentLocaleDidChangeNotification to refresh MXRoomSummaries on time formatting change.
    id NSCurrentLocaleDidChangeNotificationObserver;
    
    MXPusher *currentPusher;
}

/// Will be true if the session is not in a pauseable state or we requested for the session to pause but not finished yet. Will be reverted to false again after `resume` called.
@property (nonatomic, assign, getter=isPauseRequested) BOOL pauseRequested;
@property (nonatomic, strong) id<MXBackgroundTask> pauseBackgroundTask;
@property (nonatomic, strong) id<MXBackgroundTask> backgroundSyncBgTask;

@end

@implementation MXKAccount
@synthesize mxSession, mxRestClient;
@synthesize userPresence;
@synthesize userTintColor;
@synthesize hideUserPresence;

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initialSyncSilentErrorsHTTPStatusCodes = @[
            @(504),
            @(522),
            @(524),
            @(599)
        ];
    });
}

+ (void)registerOnCertificateChangeBlock:(MXKAccountOnCertificateChange)onCertificateChangeBlock
{
    _onCertificateChangeBlock = onCertificateChangeBlock;
}

+ (UIColor*)presenceColor:(MXPresence)presence
{
    switch (presence)
    {
        case MXPresenceOnline:
            return [[MXKAppSettings standardAppSettings] presenceColorForOnlineUser];
        case MXPresenceUnavailable:
            return [[MXKAppSettings standardAppSettings] presenceColorForUnavailableUser];
        case MXPresenceOffline:
            return [[MXKAppSettings standardAppSettings] presenceColorForOfflineUser];
        case MXPresenceUnknown:
        default:
            return nil;
    }
}

- (nonnull instancetype)initWithCredentials:(MXCredentials*)credentials
{
    if (self = [super init])
    {
        notifyOpenSessionFailure = YES;
        
        // Report credentials and alloc REST client.
        _mxCredentials = credentials;
        [self prepareRESTClient];
        
        userPresence = MXPresenceUnknown;
        
        // Refresh device information
        [self loadDeviceInformation:nil failure:nil];
        [self loadCurrentPusher:nil failure:nil];

        [self registerAccountDataDidChangeIdentityServerNotification];
        [self registerIdentityServiceDidChangeAccessTokenNotification];
    }
    return self;
}

- (void)dealloc
{
    [self closeSession:NO];
    mxSession = nil;
    
    [mxRestClient close];
    mxRestClient = nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        notifyOpenSessionFailure = YES;
        
        [self prepareRESTClient];
        
        [self registerAccountDataDidChangeIdentityServerNotification];
        [self registerIdentityServiceDidChangeAccessTokenNotification];

        userPresence = MXPresenceUnknown;
        
        // Refresh device information
        [self loadDeviceInformation:nil failure:nil];
        [self loadCurrentPusher:nil failure:nil];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setIdentityServerURL:(NSString *)identityServerURL
{
    if (identityServerURL.length)
    {
        _identityServerURL = identityServerURL;
        self.mxCredentials.identityServer = identityServerURL;
        
        // Update services used in MXSession
        [mxSession setIdentityServer:self.mxCredentials.identityServer andAccessToken:self.mxCredentials.identityServerAccessToken];
    }
    else
    {
        _identityServerURL = nil;
        [mxSession setIdentityServer:nil andAccessToken:nil];
    }
    
    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

- (void)setAntivirusServerURL:(NSString *)antivirusServerURL
{
    _antivirusServerURL = antivirusServerURL;
    // Update the current session if any
    [mxSession setAntivirusServerURL:antivirusServerURL];
    
    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

- (void)setPushGatewayURL:(NSString *)pushGatewayURL
{
    _pushGatewayURL = pushGatewayURL.length ? pushGatewayURL : nil;

    MXLogDebug(@"[MXKAccount][Push] setPushGatewayURL: %@", _pushGatewayURL);
    
    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

- (NSString*)userDisplayName
{
    if (mxSession)
    {
        return mxSession.myUser.displayname;
    }
    return nil;
}

- (NSString*)userAvatarUrl
{
    if (mxSession)
    {
        return mxSession.myUser.avatarUrl;
    }
    return nil;
}

- (NSString*)fullDisplayName
{
    if (self.userDisplayName.length)
    {
        return [NSString stringWithFormat:@"%@ (%@)", self.userDisplayName, self.mxCredentials.userId];
    }
    else
    {
        return self.mxCredentials.userId;
    }
}

- (NSArray<NSString *> *)linkedEmails
{
    NSMutableArray<NSString *> *linkedEmails = [NSMutableArray array];

    for (MXThirdPartyIdentifier *threePID in self.threePIDs)
    {
        if ([threePID.medium isEqualToString:kMX3PIDMediumEmail])
        {
            [linkedEmails addObject:threePID.address];
        }
    }

    return linkedEmails;
}

- (NSArray<NSString *> *)linkedPhoneNumbers
{
    NSMutableArray<NSString *> *linkedPhoneNumbers = [NSMutableArray array];
    
    for (MXThirdPartyIdentifier *threePID in self.threePIDs)
    {
        if ([threePID.medium isEqualToString:kMX3PIDMediumMSISDN])
        {
            [linkedPhoneNumbers addObject:threePID.address];
        }
    }
    
    return linkedPhoneNumbers;
}

- (UIColor*)userTintColor
{
    if (!userTintColor)
    {
        userTintColor = [MXKTools colorWithRGBValue:[self.mxCredentials.userId hash]];
    }
    
    return userTintColor;
}

- (BOOL)pushNotificationServiceIsActive
{
    if (currentPusher && currentPusher.enabled)
    {
        MXLogDebug(@"[MXKAccount][Push] pushNotificationServiceIsActive: currentPusher.enabled %@", currentPusher.enabled);
        return currentPusher.enabled.boolValue;
    }
    
    BOOL pushNotificationServiceIsActive = ([[MXKAccountManager sharedManager] isAPNSAvailable] && self.hasPusherForPushNotifications && mxSession);
    MXLogDebug(@"[MXKAccount][Push] pushNotificationServiceIsActive: %@", @(pushNotificationServiceIsActive));

    return pushNotificationServiceIsActive;
}

- (void)enablePushNotifications:(BOOL)enable
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *))failure
{
    MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: %@", @(enable));

    if (enable)
    {
        if (currentPusher && currentPusher.enabled && !currentPusher.enabled.boolValue)
        {
            [self.mxSession.matrixRestClient setPusherWithPushkey:currentPusher.pushkey
                                                             kind:currentPusher.kind
                                                            appId:currentPusher.appId
                                                   appDisplayName:currentPusher.appDisplayName
                                                deviceDisplayName:currentPusher.deviceDisplayName
                                                       profileTag:currentPusher.profileTag
                                                             lang:currentPusher.lang
                                                             data:currentPusher.data.JSONDictionary
                                                           append:NO
                                                          enabled:enable
                                                          success:^{
                
                MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: remotely enabled Push: Success");
                [self loadCurrentPusher:^{
                    if (success)
                    {
                        success();
                    }
                } failure:^(NSError *error) {
                    
                    MXLogWarning(@"[MXKAccount][Push] enablePushNotifications: load current pusher failed with error: %@", error);
                    if (failure)
                    {
                        failure(error);
                    }
                }];
            } failure:^(NSError *error) {

                MXLogWarning(@"[MXKAccount][Push] enablePushNotifications: remotely enable push failed with error: %@", error);
                if (failure)
                {
                    failure(error);
                }
            }];
        }
        else if ([[MXKAccountManager sharedManager] isAPNSAvailable])
        {
            MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Enable Push for %@ account", self.mxCredentials.userId);

            // Create/restore the pusher
            [self enableAPNSPusher:YES success:^{

                MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Enable Push: Success");
                if (success)
                {
                    success();
                }
            } failure:^(NSError *error) {

                MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Enable Push: Error: %@", error);
                if (failure)
                {
                    failure(error);
                }
            }];
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Error: Cannot enable Push");

            NSError *error = [NSError errorWithDomain:kMXKAccountErrorDomain
                                                 code:0
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey:
                                                            [VectorL10n accountErrorPushNotAllowed]
                                                        }];
            if (failure)
            {
                failure (error);
            }
        }
    }
    else if (self.hasPusherForPushNotifications || currentPusher)
    {
        MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Disable APNS for %@ account", self.mxCredentials.userId);
        
        // Delete the pusher, report the new value only on success.
        [self enableAPNSPusher:NO
                       success:^{

                           MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Disable Push: Success");
                           if (success)
                           {
                               success();
                           }
                       } failure:^(NSError *error) {

                           MXLogDebug(@"[MXKAccount][Push] enablePushNotifications: Disable Push: Error: %@", error);
                           if (failure)
                           {
                               failure(error);
                           }
                       }];
    }
}

- (BOOL)isPushKitNotificationActive
{
    BOOL isPushKitNotificationActive = ([[MXKAccountManager sharedManager] isPushAvailable] && self.hasPusherForPushKitNotifications && mxSession);
    MXLogDebug(@"[MXKAccount][Push] isPushKitNotificationActive: %@", @(isPushKitNotificationActive));

    return isPushKitNotificationActive;
}

- (void)enablePushKitNotifications:(BOOL)enable
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *))failure
{
    MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: %@", @(enable));

    if (enable)
    {
        if ([[MXKAccountManager sharedManager] isPushAvailable])
        {
            MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Enable Push for %@ account", self.mxCredentials.userId);

            // Create/restore the pusher
            [self enablePushKitPusher:YES success:^{

                MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Enable Push: Success");
                if (success)
                {
                    success();
                }
            } failure:^(NSError *error) {

                MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Enable Push: Error: %@", error);
                if (failure)
                {
                    failure(error);
                }
            }];
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Error: Cannot enable Push");

            NSError *error = [NSError errorWithDomain:kMXKAccountErrorDomain
                                                 code:0
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey:
                                                            [VectorL10n accountErrorPushNotAllowed]
                                                        }];
            failure (error);
        }
    }
    else if (self.hasPusherForPushKitNotifications)
    {
        MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Disable Push for %@ account", self.mxCredentials.userId);

        // Delete the pusher, report the new value only on success.
        [self enablePushKitPusher:NO success:^{

            MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Disable Push: Success");
            if (success)
            {
                success();
            }
        } failure:^(NSError *error) {

            MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: Disable Push: Error: %@", error);
            if (failure)
            {
                failure(error);
            }
        }];
    }
    else
    {
        MXLogDebug(@"[MXKAccount][Push] enablePushKitNotifications: PushKit is already disabled for %@", self.mxCredentials.userId);
        if (success)
        {
            success();
        }
    }
}

- (void)setEnableInAppNotifications:(BOOL)enableInAppNotifications
{
    MXLogDebug(@"[MXKAccount] setEnableInAppNotifications: %@", @(enableInAppNotifications));

    _enableInAppNotifications = enableInAppNotifications;
    
    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

- (void)setDisabled:(BOOL)disabled
{
    if (_disabled != disabled)
    {
        _disabled = disabled;
        
        if (_disabled)
        {
            [self deletePusher];
            [self enablePushKitNotifications:NO success:nil failure:nil];
            
            // Close session (keep the storage).
            [self closeSession:NO];
        }
        else if (!mxSession)
        {
            // Open a new matrix session
            id<MXStore> store = [[[MXKAccountManager sharedManager].storeClass alloc] init];
            
            [self openSessionWithStore:store];
        }
        
        // Archive updated field
        [[MXKAccountManager sharedManager] saveAccounts];
    }
}

- (void)setWarnedAboutEncryption:(BOOL)warnedAboutEncryption
{
    _warnedAboutEncryption = warnedAboutEncryption;

    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

- (NSMutableDictionary<NSString *, id<NSCoding>> *)others
{
    if(_others == nil) 
    {
        _others = [NSMutableDictionary dictionary];
    }
    
    return _others;
}

- (void)setPauseRequested:(BOOL)pauseRequested
{
    if (_pauseRequested != pauseRequested)
    {
        _pauseRequested = pauseRequested;

        if (_pauseRequested)
        {
            // Make sure the SDK finish its work before the app goes sleeping in background
            id<MXBackgroundModeHandler> handler = [MXSDKOptions sharedInstance].backgroundModeHandler;
            if (handler)
            {
                if (!self.pauseBackgroundTask.isRunning)
                {
                    self.pauseBackgroundTask = [handler startBackgroundTaskWithName:@"[MXKAccount] pauseInBackgroundTask"
                                                                  expirationHandler:nil];
                }
            }
        }
        else
        {
            [self cancelPauseBackgroundTask];
        }
    }
}

#pragma mark - Matrix user's profile

- (void)setUserDisplayName:(NSString*)displayname success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    if (mxSession && mxSession.myUser)
    {
        [mxSession.myUser setDisplayName:displayname
                                 success:^{
                                     if (success) {
                                         success();
                                     }
                                     
                                     [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
                                 }
                                 failure:failure];
    }
    else if (failure)
    {
        failure ([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [VectorL10n accountErrorMatrixSessionIsNotOpened]}]);
    }
}

- (void)setUserAvatarUrl:(NSString*)avatarUrl success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    if (mxSession && mxSession.myUser)
    {
        [mxSession.myUser setAvatarUrl:avatarUrl
                               success:^{
                                   if (success) {
                                       success();
                                   }
                                   
                                   [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
                               }
                               failure:failure];
    }
    else if (failure)
    {
        failure ([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [VectorL10n accountErrorMatrixSessionIsNotOpened]}]);
    }
}

- (void)changePassword:(NSString*)oldPassword with:(NSString*)newPassword logoutDevices:(BOOL)logoutDevices success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    if (mxSession)
    {
        [mxRestClient changePassword:oldPassword
                                with:newPassword
                       logoutDevices:logoutDevices
                             success:^{
                                 
                                 if (success) {
                                     success();
                                 }
                                 
                             }
                             failure:failure];
    }
    else if (failure)
    {
        failure ([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [VectorL10n accountErrorMatrixSessionIsNotOpened]}]);
    }
}

- (void)load3PIDs:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    
    [mxRestClient threePIDs:^(NSArray<MXThirdPartyIdentifier *> *threePIDs2) {
        self->_threePIDs = threePIDs2;

        // Archive updated field
        [[MXKAccountManager sharedManager] saveAccounts];

        if (success)
        {
            success();
        }

    } failure:^(NSError *error) {
        if (failure)
        {
            failure(error);
        }
    }];
}

- (void)loadCurrentPusher:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    if (!self.mxSession.myDeviceId)
    {
        MXLogWarning(@"[MXKAccount] loadPusher: device ID not found");
        if (failure)
        {
            failure([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    
    [self.mxSession supportedMatrixVersions:^(MXMatrixVersions *matrixVersions) {
        if (!matrixVersions.supportsRemotelyTogglingPushNotifications)
        {
            MXLogDebug(@"[MXKAccount] loadPusher: remotely toggling push notifications not supported");
            
            if (success)
            {
                success();
            }
            
            return;
        }
        
        [self.mxSession.matrixRestClient pushers:^(NSArray<MXPusher *> *pushers) {
            MXPusher *ownPusher;
            for (MXPusher *pusher in pushers)
            {
                if ([pusher.deviceId isEqualToString:self.mxSession.myDeviceId])
                {
                    ownPusher = pusher;
                }
            }
            
            self->currentPusher = ownPusher;
            
            if (success)
            {
                success();
            }
        } failure:^(NSError *error) {
            MXLogWarning(@"[MXKAccount] loadPusher: get pushers failed due to error %@", error);
            
            if (failure)
            {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        MXLogWarning(@"[MXKAccount] loadPusher: supportedMatrixVersions failed due to error %@", error);
        
        if (failure)
        {
            failure(error);
        }
   }];
}

- (void)loadDeviceInformation:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    if (self.mxCredentials.deviceId)
    {
        [mxRestClient deviceByDeviceId:self.mxCredentials.deviceId success:^(MXDevice *device) {
            
            self->_device = device;
            
            // Archive updated field
            [[MXKAccountManager sharedManager] saveAccounts];
            
            if (success)
            {
                success();
            }
            
        } failure:^(NSError *error) {
            
            if (failure)
            {
                failure(error);
            }
            
        }];
    }
    else
    {
        _device = nil;
        if (success)
        {
            success();
        }
    }
}

- (void)setUserPresence:(MXPresence)presence andStatusMessage:(NSString *)statusMessage completion:(void (^)(void))completion
{
    userPresence = presence;
    
    if (mxSession && !hideUserPresence)
    {
        // Update user presence on server side
        [mxSession.myUser setPresence:userPresence
                     andStatusMessage:statusMessage
                              success:^{
                                  MXLogDebug(@"[MXKAccount] %@: set user presence (%lu) succeeded", self.mxCredentials.userId, (unsigned long)self->userPresence);
                                  if (completion)
                                  {
                                      completion();
                                  }
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
                              }
                              failure:^(NSError *error) {
                                  MXLogDebug(@"[MXKAccount] %@: set user presence (%lu) failed", self.mxCredentials.userId, (unsigned long)self->userPresence);
                              }];
    }
    else if (hideUserPresence)
    {
        MXLogDebug(@"[MXKAccount] %@: set user presence is disabled.", self.mxCredentials.userId);
    }
}

#pragma mark -

/**
 Create a matrix session based on the provided store.
 When store data is ready, the live stream is automatically launched by synchronising the session with the server.
 
 In case of failure during server sync, the method is reiterated until the data is up-to-date with the server.
 This loop is stopped if you call [MXCAccount closeSession:], it is suspended if you call [MXCAccount pauseInBackgroundTask].
 
 @param store the store to use for the session.
 */
-(void)openSessionWithStore:(id<MXStore>)store
{
    // Sanity check
    if (!self.mxCredentials || !mxRestClient)
    {
        MXLogDebug(@"[MXKAccount] Matrix session cannot be created without credentials");
        return;
    }
    
    // Close potential session (keep associated store).
    [self closeSession:NO];
    
    openSessionStartDate = [NSDate date];
    
    // Instantiate new session
    mxSession = [[MXSession alloc] initWithMatrixRestClient:mxRestClient];
    mxSession.preferredSyncPresence = self.preferredSyncPresence;
    
    // Check whether an antivirus url is defined.
    if (_antivirusServerURL)
    {
        // Enable the antivirus scanner in the current session.
        [mxSession setAntivirusServerURL:_antivirusServerURL];
    }

    // Set default MXEvent -> NSString formatter
    MXKEventFormatter *eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:self.mxSession];
    eventFormatter.isForSubtitle = YES;

    // Apply the event types filter to display only the wanted event types.
    eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;

    mxSession.roomSummaryUpdateDelegate = eventFormatter;

    // Observe UIApplicationSignificantTimeChangeNotification to refresh to MXRoomSummaries if date/time are shown.
    // UIApplicationSignificantTimeChangeNotification is posted if DST is updated, carrier time is updated
    UIApplicationSignificantTimeChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationSignificantTimeChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        [self onDateTimeFormatUpdate];
    }];


    // Observe NSCurrentLocaleDidChangeNotification to refresh MXRoomSummaries if date/time are shown.
    // NSCurrentLocaleDidChangeNotification is triggered when the time swicthes to AM/PM to 24h time format
    NSCurrentLocaleDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        [self onDateTimeFormatUpdate];
    }];
    
    // Force a date refresh for all the last messages.
    [self onDateTimeFormatUpdate];

    // Register session state observer
    sessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Check whether the concerned session is the associated one
        if (notif.object == self->mxSession)
        {
            [self onMatrixSessionStateChange];
        }
    }];
    
    MXWeakify(self);
    
    [mxSession setStore:store success:^{
        
        // Complete session registration by launching live stream
        MXStrongifyAndReturnIfNil(self);
        
        // Validate the availability of local contact sync for any changes to the
        // authorization of contacts access that may have occurred since the last launch.
        // The session is passed in as the contacts manager may not have had a session added yet.
        [MXKContactManager.sharedManager validateSyncLocalContactsStateForSession:self.mxSession];
        
        // Refresh pusher state
        [self loadCurrentPusher:^{
            [self refreshAPNSPusher];
        } failure:nil];
        [self refreshPushKitPusher];
        
        // Launch server sync
        [self launchInitialServerSync];
        
    } failure:^(NSError *error) {
        
        // This cannot happen. Loading of MXFileStore cannot fail.
        MXStrongifyAndReturnIfNil(self);
        self->mxSession = nil;
        
        NSString *myUserId = self.mxSession.myUser.userId;
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self->sessionStateObserver];
        self->sessionStateObserver = nil;
        
    }];
}

/**
 Close the matrix session.
 
 @param clearStore set YES to delete all store data.
 */
- (void)closeSession:(BOOL)clearStore
{
    MXLogDebug(@"[MXKAccount] closeSession (%u)", clearStore);
    
    if (NSCurrentLocaleDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:NSCurrentLocaleDidChangeNotificationObserver];
        NSCurrentLocaleDidChangeNotificationObserver = nil;
    }

    if (UIApplicationSignificantTimeChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationSignificantTimeChangeNotificationObserver];
        UIApplicationSignificantTimeChangeNotificationObserver = nil;
    }
    
    [self removeNotificationListener];
    
    if (reachabilityObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
    }
    
    if (sessionStateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
        sessionStateObserver = nil;
    }
    
    if (userUpdateListener)
    {
        [mxSession.myUser removeListener:userUpdateListener];
        userUpdateListener = nil;
    }
    
    if (mxSession)
    {
        // Reset room data stored in memory
        [MXKRoomDataSourceManager removeSharedManagerForMatrixSession:mxSession];

        if (clearStore)
        {   
            // Clean other stores
            [mxSession.scanManager deleteAllAntivirusScans];
            [mxSession.aggregations resetData];
        }
        else
        {
            // For recomputing of room summaries as they are a cache of computed data
            [mxSession resetRoomsSummariesLastMessage];
        }

        // Close session
        [mxSession close];
        
        if (clearStore)
        {
            [mxSession.store deleteAllData];
        }
        
        mxSession = nil;
    }
    
    notifyOpenSessionFailure = YES;
}

- (void)logout:(void (^)(void))completion 
{
    if (!mxSession || !mxSession.matrixRestClient)
    {
        MXLogDebug(@"[MXKAccount] logout: Need to open the closed session to make a logout request");
        id<MXStore> store = [[[MXKAccountManager sharedManager].storeClass alloc] init];
        mxSession = [[MXSession alloc] initWithMatrixRestClient:mxRestClient];

        MXWeakify(self);
        [mxSession setStore:store success:^{
            MXStrongifyAndReturnIfNil(self);

            [self logout:completion];

        } failure:^(NSError *error) {
            completion();
        }];
        return;
    }

    [self deletePusher];
    [self enablePushKitNotifications:NO success:nil failure:nil];
    
    MXHTTPOperation *operation = [mxSession logout:^{
        
        [self closeSession:YES];
        if (completion)
        {
            completion();
        }
        
    } failure:^(NSError *error) {
        
        // Close the session even if the logout request failed
        [self closeSession:YES];
        if (completion)
        {
            completion();
        }
        
    }];
    
    // Do not retry on failure.
    operation.maxNumberOfTries = 1;
}

// Logout locally, do not send server request
- (void)logoutLocally:(void (^)(void))completion
{
    [self deletePusher];
    [self enablePushKitNotifications:NO success:nil failure:nil];
    
    [mxSession enableCrypto:NO success:^{
        [self closeSession:YES];
        if (completion)
        {
            completion();
        }
        
    } failure:^(NSError *error) {
        
        // Close the session even if the logout request failed
        [self closeSession:YES];
        if (completion)
        {
            completion();
        }
        
    }];
}

- (void)logoutSendingServerRequest:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(void))completion
{
    if (sendLogoutServerRequest)
    {
        [self logout:completion];
    }
    else
    {
        [self logoutLocally:completion];
    }
}


#pragma mark - Soft logout

- (void)softLogout
{
    if (_isSoftLogout)
    {
        //  do not close the session if already soft logged out
        //  it may break the current logout request and resetting session credentials can cause crashes
        return;
    }
    _isSoftLogout = YES;
    [[MXKAccountManager sharedManager] saveAccounts];

    // Stop SDK making requests to the homeserver
    [mxSession close];
}

- (void)hydrateWithCredentials:(MXCredentials*)credentials
{
    // Sanity check
    if ([self.mxCredentials.userId isEqualToString:credentials.userId])
    {
        _mxCredentials = credentials;
        _isSoftLogout = NO;
        [[MXKAccountManager sharedManager] saveAccounts];

        [self prepareRESTClient];
    }
    else
    {
        MXLogDebug(@"[MXKAccount] hydrateWithCredentials: Error: users ids mismatch: %@ vs %@", credentials.userId, self.mxCredentials.userId);
    }
}

- (void)deletePusher
{
    if (self.pushNotificationServiceIsActive)
    {
        [self enableAPNSPusher:NO success:nil failure:nil];
    }
}

- (void)pauseInBackgroundTask
{
    if (mxSession == nil)
    {
        //  no session to pause
        return;
    }

    //  mark that we want to pause when possible
    self.pauseRequested = YES;

    if (mxSession.isPauseable)
    {
        // Pause SDK
        [mxSession pause];
        
        // Update user presence
        MXWeakify(self);
        [self setUserPresence:MXPresenceOffline andStatusMessage:nil completion:^{
            MXStrongifyAndReturnIfNil(self);
            [self cancelPauseBackgroundTask];
        }];
    }
    else
    {
        // Cancel pending actions
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;

        MXLogDebug(@"[MXKAccount] Pause is delayed due to the session state: %@", [MXTools readableSessionState: mxSession.state]);
    }
}

- (void)resume
{
    if (mxSession == nil)
    {
        //  no session to resume
        return;
    }

    //  mark that we don't want to pause anymore
    self.pauseRequested = NO;

    MXLogVerbose(@"[MXKAccount] resume: with session state: %@", [MXTools readableSessionState:mxSession.state]);

    [self cancelBackgroundSync];

    switch (mxSession.state)
    {
        case MXSessionStatePaused:
        case MXSessionStatePauseRequested:
        {
            // Resume SDK and update user presence
            MXWeakify(self);
            [mxSession resume:^{
                MXStrongifyAndReturnIfNil(self);
                [self setUserPresence:self.preferredSyncPresence andStatusMessage:nil completion:nil];

                [self refreshAPNSPusher];
                [self refreshPushKitPusher];
            }];

            break;
        }
        case MXSessionStateStoreDataReady:
        case MXSessionStateInitialSyncFailed:
        {
            // The session initialisation was uncompleted, we try to complete it here.
            [self launchInitialServerSync];

            [self refreshAPNSPusher];
            [self refreshPushKitPusher];

            break;
        }
        case MXSessionStateSyncInProgress:
        {
            [self refreshAPNSPusher];
            [self refreshPushKitPusher];

            break;
        }
        default:
            break;
    }
}

- (void)reload:(BOOL)clearCache
{
    // close potential session
    [self closeSession:clearCache];
    
    if (!_disabled)
    {
        // Open a new matrix session
        id<MXStore> store = [[[MXKAccountManager sharedManager].storeClass alloc] init];
        [self openSessionWithStore:store];
    }
}

#pragma mark - Push notifications

// Refresh the APNS pusher state for this account on this device.
- (void)refreshAPNSPusher
{
    MXLogDebug(@"[MXKAccount][Push] refreshAPNSPusher");
    
    if (currentPusher)
    {
        MXLogDebug(@"[MXKAccount][Push] refreshAPNSPusher aborted as a pusher has been found");
        return;
    }

    // Check the conditions required to run the pusher
    if (self.pushNotificationServiceIsActive)
    {
        MXLogDebug(@"[MXKAccount][Push] refreshAPNSPusher: Refresh APNS pusher for %@ account", self.mxCredentials.userId);
        
        // Create/restore the pusher
        [self enableAPNSPusher:YES
                       success:nil
                       failure:^(NSError *error) {
                           MXLogDebug(@"[MXKAccount][Push] ;: Error: %@", error);
                       }];
    }
    else if (_hasPusherForPushNotifications)
    {
        if ([MXKAccountManager sharedManager].apnsDeviceToken)
        {
            if (mxSession)
            {
                // Turn off pusher if user denied remote notification.
                MXLogDebug(@"[MXKAccount][Push] refreshAPNSPusher: Disable APNS pusher for %@ account (notifications are denied)", self.mxCredentials.userId);
                [self enableAPNSPusher:NO success:nil failure:nil];
            }
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] refreshAPNSPusher: APNS pusher for %@ account is already disabled. Reset _hasPusherForPushNotifications", self.mxCredentials.userId);
            _hasPusherForPushNotifications = NO;
            [[MXKAccountManager sharedManager] saveAccounts];
        }
    }
}

// Enable/Disable the APNS pusher for this account on this device on the homeserver.
- (void)enableAPNSPusher:(BOOL)enabled success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    MXLogDebug(@"[MXKAccount][Push] enableAPNSPusher: %@", @(enabled));

#ifdef DEBUG
    NSString *appId = [[NSUserDefaults standardUserDefaults] objectForKey:@"pusherAppIdDev"];
#else
    NSString *appId = [[NSUserDefaults standardUserDefaults] objectForKey:@"pusherAppIdProd"];
#endif
    
    NSString *locKey = MXKAppSettings.standardAppSettings.notificationBodyLocalizationKey;
    
    NSDictionary *pushData = @{
        @"url": self.pushGatewayURL,
        @"format": @"event_id_only",
        @"default_payload": @{@"aps": @{@"mutable-content": @(1), @"alert": @{@"loc-key": locKey, @"loc-args": @[]}}}
    };
    
    [self enablePusher:enabled appId:appId token:[MXKAccountManager sharedManager].apnsDeviceToken pushData:pushData success:^{
        
        MXLogDebug(@"[MXKAccount][Push] enableAPNSPusher: Succeeded to update APNS pusher for %@ (%d)", self.mxCredentials.userId, enabled);

        self->_hasPusherForPushNotifications = enabled;
        [[MXKAccountManager sharedManager] saveAccounts];
        
        if (enabled)
        {
            [self loadCurrentPusher:^{
                if (success)
                {
                    success();
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountAPNSActivityDidChangeNotification object:self.mxCredentials.userId];
            } failure:^(NSError *error) {
                if (success)
                {
                    success();
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountAPNSActivityDidChangeNotification object:self.mxCredentials.userId];
            }];
        }
        else
        {
            self->currentPusher = nil;
            
            if (success)
            {
                success();
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountAPNSActivityDidChangeNotification object:self.mxCredentials.userId];
        }
        
    } failure:^(NSError *error) {
        
        // Ignore error if the client try to disable an unknown token
        if (!enabled)
        {
            // Check whether the token was unknown
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringUnknown])
            {
                MXLogDebug(@"[MXKAccount][Push] enableAPNSPusher: APNS was already disabled for %@!", self.mxCredentials.userId);
                
                // Ignore the error
                if (success)
                {
                    success();
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountAPNSActivityDidChangeNotification object:self.mxCredentials.userId];
                
                return;
            }
            
            MXLogDebug(@"[MXKAccount][Push] enableAPNSPusher: Failed to disable APNS %@! (%@)", self.mxCredentials.userId, error);
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] enableAPNSPusher: Failed to send APNS token for %@! (%@)", self.mxCredentials.userId, error);
        }
        
        if (failure)
        {
            failure(error);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountAPNSActivityDidChangeNotification object:self.mxCredentials.userId];
    }];
}

// Refresh the PushKit pusher state for this account on this device.
- (void)refreshPushKitPusher
{
    MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher");

    // Check the conditions required to run the pusher
    if (![MXKAppSettings standardAppSettings].allowPushKitPushers)
    {
        // Turn off pusher if PushKit pushers are not allowed
        MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher: Disable PushKit pusher for %@ account (pushers are not allowed)", self.mxCredentials.userId);
        [self enablePushKitPusher:NO success:nil failure:nil];
    }
    else if (self.isPushKitNotificationActive)
    {
        MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher: Refresh PushKit pusher for %@ account", self.mxCredentials.userId);
        
        // Create/restore the pusher
        [self enablePushKitPusher:YES
                          success:nil
                          failure:^(NSError *error) {
                              MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher: Error: %@", error);
                          }];
    }
    else if (self.hasPusherForPushKitNotifications)
    {
        if ([MXKAccountManager sharedManager].pushDeviceToken)
        {
            if (mxSession)
            {
                // Turn off pusher if user denied remote notification.
                MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher: Disable PushKit pusher for %@ account (notifications are denied)", self.mxCredentials.userId);
                [self enablePushKitPusher:NO success:nil failure:nil];
            }
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] refreshPushKitPusher: PushKit pusher for %@ account is already disabled. Reset _hasPusherForPushKitNotifications", self.mxCredentials.userId);
            self->_hasPusherForPushKitNotifications = NO;
            [[MXKAccountManager sharedManager] saveAccounts];
        }
    }
}

// Enable/Disable the pusher based on PushKit for this account on this device on the homeserver.
- (void)enablePushKitPusher:(BOOL)enabled success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: %@", @(enabled));
    
    if (enabled && ![MXKAppSettings standardAppSettings].allowPushKitPushers)
    {
        //  sanity check, if accidently try to enable the pusher
        MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Do not enable it because PushKit pushers not allowed");
        if (failure)
        {
            failure([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]);
        }
        return;
    }

    NSString *appIdKey;
    #ifdef DEBUG
        appIdKey = @"pushKitAppIdDev";
    #else
        appIdKey = @"pushKitAppIdProd";
    #endif

    NSString *appId = [[NSUserDefaults standardUserDefaults] objectForKey:appIdKey];
    
    NSMutableDictionary *pushData = [NSMutableDictionary dictionaryWithDictionary:@{@"url": self.pushGatewayURL}];
    
    NSDictionary *options = [MXKAccountManager sharedManager].pushOptions;
    if (options.count)
    {
        [pushData addEntriesFromDictionary:options];
    }

    NSData *token = [MXKAccountManager sharedManager].pushDeviceToken;
    if (!token)
    {
        //  sanity check, if no token there is no point of calling the endpoint
        MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Failed to update PushKit pusher to %@ for %@. (token is missing)", @(enabled), self.mxCredentials.userId);
        if (failure)
        {
            failure([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]);
        }
        return;
    }
    [self enablePusher:enabled appId:appId token:token pushData:pushData success:^{
        
        MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Succeeded to update PushKit pusher for %@. Enabled: %@. Token: %@", self.mxCredentials.userId, @(enabled), [MXKTools logForPushToken:token]);

        self->_hasPusherForPushKitNotifications = enabled;
        [[MXKAccountManager sharedManager] saveAccounts];
        
        if (success)
        {
            success();
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountPushKitActivityDidChangeNotification object:self.mxCredentials.userId];
        
    } failure:^(NSError *error) {
        
        // Ignore error if the client try to disable an unknown token
        if (!enabled)
        {
            // Check whether the token was unknown
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringUnknown])
            {
                MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Push was already disabled for %@!", self.mxCredentials.userId);
                
                // Ignore the error
                if (success)
                {
                    success();
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountPushKitActivityDidChangeNotification object:self.mxCredentials.userId];
                
                return;
            }
            
            MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Failed to disable Push %@! (%@)", self.mxCredentials.userId, error);
        }
        else
        {
            MXLogDebug(@"[MXKAccount][Push] enablePushKitPusher: Failed to send Push token for %@! (%@)", self.mxCredentials.userId, error);
        }
        
        if (failure)
        {
            failure(error);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountPushKitActivityDidChangeNotification object:self.mxCredentials.userId];
    }];
}

- (void)enablePusher:(BOOL)enabled appId:(NSString*)appId token:(NSData*)token pushData:(NSDictionary*)pushData success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    MXLogDebug(@"[MXKAccount][Push] enablePusher: %@", @(enabled));

    // Refuse to try & turn push on if we're not logged in, it's nonsensical.
    if (!self.mxCredentials)
    {
        MXLogDebug(@"[MXKAccount][Push] enablePusher: Not setting push token because we're not logged in");
        return;
    }
    
    // Check whether the Push Gateway URL has been configured.
    if (!self.pushGatewayURL)
    {
        MXLogDebug(@"[MXKAccount][Push] enablePusher: Not setting pusher because the Push Gateway URL is undefined");
        return;
    }
    
    if (!appId)
    {
        MXLogDebug(@"[MXKAccount][Push] enablePusher: Not setting pusher because pusher app id is undefined");
        return;
    }
    
    NSString *appDisplayName = [NSString stringWithFormat:@"%@ (iOS)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
    
    NSString *b64Token = [token base64EncodedStringWithOptions:0];
    
    NSString *deviceLang = [NSLocale preferredLanguages][0];
    
    NSString * profileTag = [[NSUserDefaults standardUserDefaults] valueForKey:@"pusherProfileTag"];
    if (!profileTag)
    {
        profileTag = @"";
        NSString *alphabet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (int i = 0; i < 16; ++i)
        {
            unsigned char c = [alphabet characterAtIndex:arc4random() % alphabet.length];
            profileTag = [profileTag stringByAppendingFormat:@"%c", c];
        }
        MXLogDebug(@"[MXKAccount][Push] enablePusher: Generated fresh profile tag: %@", profileTag);
        [[NSUserDefaults standardUserDefaults] setValue:profileTag forKey:@"pusherProfileTag"];
    }
    else
    {
        MXLogDebug(@"[MXKAccount][Push] enablePusher: Using existing profile tag: %@", profileTag);
    }
    
    NSObject *kind = enabled ? @"http" : [NSNull null];
    
    // Use the append flag to handle multiple accounts registration.
    BOOL append = NO;
    // Check whether a pusher is running for another account
    NSArray *activeAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in activeAccounts)
    {
        if (![account.mxCredentials.userId isEqualToString:self.mxCredentials.userId] && account.pushNotificationServiceIsActive)
        {
            append = YES;
            break;
        }
    }
    MXLogDebug(@"[MXKAccount][Push] enablePusher: append flag: %d", append);
    
    MXRestClient *restCli = self.mxRestClient;
    
    [restCli setPusherWithPushkey:b64Token kind:kind appId:appId appDisplayName:appDisplayName deviceDisplayName:[[UIDevice currentDevice] name] profileTag:profileTag lang:deviceLang data:pushData append:append enabled:enabled success:success failure:failure];
}

#pragma mark - InApp notifications

- (void)listenToNotifications:(MXOnNotification)onNotification
{
    // Check conditions required to add notification listener
    if (!mxSession || !onNotification)
    {
        return;
    }
    
    // Remove existing listener (if any)
    [self removeNotificationListener];
    
    // Register on notification center
    notificationCenterListener = [self.mxSession.notificationCenter listenToNotifications:^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule)
    {
        // Apply first the event filter defined in the related room data source
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self->mxSession];
        [roomDataSourceManager roomDataSourceForRoom:event.roomId create:NO onComplete:^(MXKRoomDataSource *roomDataSource) {
            if (roomDataSource)
            {
                if (!roomDataSource.eventFormatter.eventTypesFilterForMessages || [roomDataSource.eventFormatter.eventTypesFilterForMessages indexOfObject:event.type] != NSNotFound)
                {
                    // Check conditions to report this notification
                    if (nil == self->ignoredRooms || [self->ignoredRooms indexOfObject:event.roomId] == NSNotFound)
                    {
                        onNotification(event, roomState, rule);
                    }
                }
            }
        }];
    }];
}

- (void)removeNotificationListener
{
    if (notificationCenterListener)
    {
        [self.mxSession.notificationCenter removeListener:notificationCenterListener];
        notificationCenterListener = nil;
    }
    ignoredRooms = nil;
}

- (void)updateNotificationListenerForRoomId:(NSString*)roomID ignore:(BOOL)isIgnored
{
    if (isIgnored)
    {
        if (!ignoredRooms)
        {
            ignoredRooms = [[NSMutableArray alloc] init];
        }
        [ignoredRooms addObject:roomID];
    }
    else if (ignoredRooms)
    {
        [ignoredRooms removeObject:roomID];
    }
}

#pragma mark - Internals

- (void)launchInitialServerSync
{
    // Complete the session registration when store data is ready.
    
    // Cancel potential reachability observer and pending action
    [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
    reachabilityObserver = nil;
    
    // Sanity check
    if (!mxSession || (mxSession.state != MXSessionStateStoreDataReady && mxSession.state != MXSessionStateInitialSyncFailed))
    {
        MXLogDebug(@"[MXKAccount] Initial server sync is applicable only when store data is ready to complete session initialisation");
        return;
    }

    // Use /sync filter corresponding to current settings and homeserver capabilities
    MXWeakify(self);
    [self buildSyncFilter:^(MXFilterJSONModel *syncFilter) {
        MXStrongifyAndReturnIfNil(self);

        // Make sure the filter is compatible with the previously used one
        MXWeakify(self);
        [self checkSyncFilterCompatibility:syncFilter completion:^(BOOL compatible) {
            MXStrongifyAndReturnIfNil(self);

            if (!compatible)
            {
                // Else clear the cache
                MXLogDebug(@"[MXKAccount] New /sync filter not compatible with previous one. Clear cache");

                [self reload:YES];
                return;
            }

            // Launch mxSession
            MXWeakify(self);
            [self.mxSession startWithSyncFilter:syncFilter onServerSyncDone:^{
                MXStrongifyAndReturnIfNil(self);

                MXLogDebug(@"[MXKAccount] %@: The session is ready. Matrix SDK session has been started in %0.fms.", self.mxCredentials.userId, [[NSDate date] timeIntervalSinceDate:self->openSessionStartDate] * 1000);

                [self setUserPresence:self.preferredSyncPresence andStatusMessage:nil completion:nil];

            } failure:^(NSError *error) {
                MXStrongifyAndReturnIfNil(self);

                MXLogDebug(@"[MXKAccount] Initial Sync failed. Error: %@", error);
                
                BOOL isClientTimeout = [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut;
                NSHTTPURLResponse *httpResponse = [MXHTTPOperation urlResponseFromError:error];
                BOOL isServerTimeout = httpResponse && [initialSyncSilentErrorsHTTPStatusCodes containsObject:@(httpResponse.statusCode)];
                
                if (isClientTimeout || isServerTimeout)
                {
                    //  do not propagate this error to the client
                    //  the request will be retried or postponed according to the reachability status
                    MXLogDebug(@"[MXKAccount] Initial sync failure did not propagated");
                }
                else if (self->notifyOpenSessionFailure && error)
                {
                    // Notify MatrixKit user only once
                    self->notifyOpenSessionFailure = NO;
                    NSString *myUserId = self.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                }
                
                // If we cannot resolve this error by retrying, exit early
                BOOL isRetryableError = [error.domain isEqualToString:NSURLErrorDomain] || [MXHTTPOperation urlResponseFromError:error] != nil;
                if (!isRetryableError)
                {
                    MXLogDebug(@"[MXKAccount] Initial sync will not be retried");
                    return;
                }

                // Check if it is a network connectivity issue
                AFNetworkReachabilityManager *networkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
                MXLogDebug(@"[MXKAccount] Network reachability: %d", networkReachabilityManager.isReachable);

                if (networkReachabilityManager.isReachable)
                {
                    // If we have network, we retry immediately, otherwise the server may clear any cache it has computed thus far
                    [self launchInitialServerSync];
                }
                else
                {
                    // The device is not connected to the internet, wait for the connection to be up again before retrying
                    // Add observer to launch a new attempt according to reachability.
                    self->reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

                        NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
                        if (statusItem)
                        {
                            AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                            if (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN)
                            {
                                // New attempt
                                [self launchInitialServerSync];
                            }
                        }

                    }];
                }
            }];
        }];
    }];
}

- (void)onMatrixSessionStateChange
{
    // Check if pause has been requested
    if (self.isPauseRequested && mxSession.isPauseable)
    {
        MXLogDebug(@"[MXKAccount] Apply the pending pause.");
        [self pauseInBackgroundTask];
        return;
    }

    if (mxSession.state == MXSessionStateRunning)
    {
        // Check whether the session was not already running
        if (!userUpdateListener)
        {
            // Register listener to user's information change
            userUpdateListener = [mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
                // Consider events related to user's presence
                if (event.eventType == MXEventTypePresence)
                {
                    self->userPresence = [MXTools presence:event.content[@"presence"]];
                }
                
                // Here displayname or other information have been updated, post update notification.
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
            }];
            
            // User information are just up-to-date (`mxSession` is running), post update notification.
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
        }
    }
    else if (mxSession.state == MXSessionStateStoreDataReady || mxSession.state == MXSessionStateSyncInProgress)
    {
        // Remove listener (if any), this action is required to handle correctly matrix sdk handler reload (see clear cache)
        if (userUpdateListener)
        {
            [mxSession.myUser removeListener:userUpdateListener];
            userUpdateListener = nil;
        }
        else
        {
            // Here the initial server sync is in progress. The session is not running yet, but some user's information are available (from local storage).
            // We post update notification to let observer take into account this user's information even if they may not be up-to-date.
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKAccountUserInfoDidChangeNotification object:self.mxCredentials.userId];
        }
    }
    else if (mxSession.state == MXSessionStatePaused)
    {
        self.pauseRequested = NO;
    }
}

- (void)prepareRESTClient
{
    if (!self.mxCredentials)
    {
        return;
    }
    MXWeakify(self);
    mxRestClient = [[MXRestClient alloc] initWithCredentials:self.mxCredentials andOnUnrecognizedCertificateBlock:^BOOL(NSData *certificate) {
        MXStrongifyAndReturnValueIfNil(self, NO);
        if (_onCertificateChangeBlock)
        {
            if (_onCertificateChangeBlock (self, certificate))
            {
                // Update the certificate in credentials
                self.mxCredentials.allowedCertificate = certificate;
                
                // Archive updated field
                [[MXKAccountManager sharedManager] saveAccounts];
                
                return YES;
            }
            
            self.mxCredentials.ignoredCertificate = certificate;
            
            // Archive updated field
            [[MXKAccountManager sharedManager] saveAccounts];
        }
        return NO;
    
    } andPersistentTokenDataHandler:^(void (^handler)(NSArray<MXCredentials *> *credentials, void (^completion)(BOOL didUpdateCredentials))) {
        [MXKAccountManager.sharedManager readAndWriteCredentials:handler];
    } andUnauthenticatedHandler:^(MXError *error, BOOL isSoftLogout, BOOL isRefreshTokenAuth, void (^completion)(void)) {
        MXStrongifyAndReturnIfNil(self);
        [self handleUnauthenticatedWithError:error isSoftLogout:isSoftLogout isRefreshTokenAuth:isRefreshTokenAuth andCompletion:completion];
    }];
}

- (void)handleUnauthenticatedWithError:(MXError *)error isSoftLogout:(BOOL)isSoftLogout isRefreshTokenAuth:(BOOL)isRefreshTokenAuth andCompletion:(void (^)(void))completion
{
    
    [Analytics.shared trackAuthUnauthenticatedErrorWithSoftLogout:isSoftLogout refreshTokenAuth:isRefreshTokenAuth errorCode:error.errcode errorReason:error.error];
    MXLogDebug(@"[MXKAccountManager] handleUnauthenticated: trackAuthUnauthenticatedErrorWithSoftLogout sent");
    if (isSoftLogout)
    {
        MXLogDebug(@"[MXKAccountManager] handleUnauthenticated: soft logout.");
        [[MXKAccountManager sharedManager] softLogout:self];
        completion();
    }
    else
    {
        MXLogDebug(@"[MXKAccountManager] handleUnauthenticated: hard logout.");
        [[MXKAccountManager sharedManager] removeAccount:self sendLogoutRequest:NO completion:completion];
    }
}

- (void)onDateTimeFormatUpdate
{
    if ([mxSession.roomSummaryUpdateDelegate isKindOfClass:MXKEventFormatter.class])
    {
        MXKEventFormatter *eventFormatter = (MXKEventFormatter*)mxSession.roomSummaryUpdateDelegate;
        
        // Update the date and time formatters
        [eventFormatter initDateTimeFormatters];
        
        dispatch_group_t dispatchGroup = dispatch_group_create();
        
        for (MXRoom *room in mxSession.rooms)
        {
            MXRoomSummary *summary = room.summary;
            if (summary)
            {
                NSString *eventId = summary.lastMessage.eventId;
                if (!eventId)
                {
                    MXLogFailure(@"[MXKAccount] onDateTimeFormatUpdate: Missing event id");
                    continue;
                }
                
                dispatch_group_enter(dispatchGroup);
                [summary.mxSession eventWithEventId:eventId
                                             inRoom:summary.roomId
                                            success:^(MXEvent *event) {
                    
                    if (event)
                    {
                        if (summary.lastMessage.others == nil)
                        {
                            summary.lastMessage.others = [NSMutableDictionary dictionary];
                        }
                        summary.lastMessage.others[@"lastEventDate"] = [eventFormatter dateStringFromEvent:event withTime:YES];
                        [self->mxSession.store.roomSummaryStore storeSummary:summary];
                    }
                    
                    dispatch_group_leave(dispatchGroup);
                } failure:^(NSError *error) {
                    MXLogErrorDetails(@"[MXKAccount] onDateTimeFormatUpdate: event fetch failed", @{
                        @"error": error ?: @"unknown"
                    });
                    dispatch_group_leave(dispatchGroup);
                }];
            }
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            
            // Commit store changes done
            if ([self->mxSession.store respondsToSelector:@selector(commit)])
            {
                [self->mxSession.store commit];
            }
            
            // Broadcast the change which concerns all the room summaries.
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXRoomSummaryDidChangeNotification object:nil userInfo:nil];
            
        });
    }
}

- (void)cancelPauseBackgroundTask
{
    // Cancel background task
    if (self.pauseBackgroundTask.isRunning)
    {
        [self.pauseBackgroundTask stop];
        self.pauseBackgroundTask = nil;
    }
}

#pragma mark - Crypto
- (void)resetDeviceId
{
    self.mxCredentials.deviceId = nil;

    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

#pragma mark - backgroundSync management

- (void)cancelBackgroundSync
{
    if (self.backgroundSyncBgTask.isRunning)
    {
        MXLogDebug(@"[MXKAccount] The background Sync is cancelled.");
        
        if (mxSession)
        {
            if (mxSession.state == MXSessionStateBackgroundSyncInProgress)
            {
                [mxSession pause];
            }
        }
        
        [self onBackgroundSyncDone:[NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]];
    }
}

- (void)onBackgroundSyncDone:(NSError*)error
{
    if (backgroundSyncTimer)
    {
        [backgroundSyncTimer invalidate];
        backgroundSyncTimer = nil;
    }
    
    if (backgroundSyncFails && error)
    {
        backgroundSyncFails(error);
    }
    
    if (backgroundSyncDone && !error)
    {
        backgroundSyncDone();
    }
    
    backgroundSyncDone = nil;
    backgroundSyncFails = nil;
    
    // End background task
    if (self.backgroundSyncBgTask.isRunning)
    {
        [self.backgroundSyncBgTask stop];
        self.backgroundSyncBgTask = nil;
    }
}

- (void)onBackgroundSyncTimerOut
{
    [self cancelBackgroundSync];
}

- (void)backgroundSync:(unsigned int)timeout success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // Check whether a background mode handler has been set.
    id<MXBackgroundModeHandler> handler = [MXSDKOptions sharedInstance].backgroundModeHandler;
    if (handler)
    {
        // Only work when the application is suspended.
        // Check conditions before launching background sync
        if (mxSession && mxSession.state == MXSessionStatePaused)
        {
            MXLogDebug(@"[MXKAccount] starts a background Sync");
            
            backgroundSyncDone = success;
            backgroundSyncFails = failure;
            
            MXWeakify(self);
            
            self.backgroundSyncBgTask = [handler startBackgroundTaskWithName:@"[MXKAccount] backgroundSync:success:failure:" expirationHandler:^{
                
                MXStrongifyAndReturnIfNil(self);
                
                MXLogDebug(@"[MXKAccount] the background Sync fails because of the bg task timeout");
                [self cancelBackgroundSync];
            }];
            
            // ensure that the backgroundSync will be really done in the expected time
            // the request could be done but the treatment could be long so add a timer to cancel it
            // if it takes too much time
            backgroundSyncTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:(timeout - 1) / 1000]
                                                           interval:0
                                                             target:self
                                                           selector:@selector(onBackgroundSyncTimerOut)
                                                           userInfo:nil
                                                            repeats:NO];
            
            [[NSRunLoop mainRunLoop] addTimer:backgroundSyncTimer forMode:NSDefaultRunLoopMode];
            
            [mxSession backgroundSync:timeout success:^{
                MXLogDebug(@"[MXKAccount] the background Sync succeeds");
                [self onBackgroundSyncDone:nil];
                
            }
                              failure:^(NSError* error) {
                                  
                                  MXLogDebug(@"[MXKAccount] the background Sync fails");
                                  [self onBackgroundSyncDone:error];
                                  
                              }
             
             ];
        }
        else
        {
            MXLogDebug(@"[MXKAccount] cannot start background Sync (invalid state %@)", [MXTools readableSessionState:mxSession.state]);
            failure([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]);
        }
    }
    else
    {
        MXLogDebug(@"[MXKAccount] cannot start background Sync");
        failure([NSError errorWithDomain:kMXKAccountErrorDomain code:0 userInfo:nil]);
    }
}

#pragma mark - Sync filter

- (void)supportLazyLoadOfRoomMembersWithMatrixVersion:(MXMatrixVersions *)matrixVersions
                                           completion:(void (^)(BOOL supportLazyLoadOfRoomMembers))completion
{
    void(^onUnsupportedLazyLoadOfRoomMembers)(NSError *) = ^(NSError *error) {
        completion(NO);
    };

    // Check if the server supports LL sync filter
    MXFilterJSONModel *filter = [self syncFilterWithLazyLoadOfRoomMembers:YES supportsNotificationsForThreads:NO];
    [mxSession.store filterIdForFilter:filter success:^(NSString * _Nullable filterId) {

        if (filterId)
        {
            // The LL filter is already in the store. The HS supports LL
            completion(YES);
        }
        else
        {
            // Check the Matrix versions supported by the HS
            if (matrixVersions)
            {
                if (matrixVersions.supportLazyLoadMembers)
                {
                    // The HS supports LL
                    completion(YES);
                }
                else
                {
                    onUnsupportedLazyLoadOfRoomMembers(nil);
                }
            }
            else
            {
                completion(NO);
            }
        }
    } failure:onUnsupportedLazyLoadOfRoomMembers];
}

/**
 Build the sync filter according to application settings and HS capability.

 @param completion the block providing the sync filter to use.
 */
- (void)buildSyncFilter:(void (^)(MXFilterJSONModel *syncFilter))completion
{
    // Check settings
    BOOL syncWithLazyLoadOfRoomMembersSetting = [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers;

    void(^buildSyncFilter)(MXMatrixVersions *) = ^(MXMatrixVersions *matrixVersions) {
        BOOL supportsNotificationsForThreads = matrixVersions ? matrixVersions.supportsNotificationsForThreads : NO;
        
        if (syncWithLazyLoadOfRoomMembersSetting)
        {
            // Check if the server supports LL sync filter before enabling it
            [self supportLazyLoadOfRoomMembersWithMatrixVersion:matrixVersions completion:^(BOOL supportLazyLoadOfRoomMembers) {
                

                if (supportLazyLoadOfRoomMembers)
                {
                    completion([self syncFilterWithLazyLoadOfRoomMembers:YES
                                         supportsNotificationsForThreads:supportsNotificationsForThreads]);
                }
                else
                {
                    // No support from the HS
                    // Disable the setting. That will avoid to make a request at every startup
                    [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers = NO;
                    completion([self syncFilterWithLazyLoadOfRoomMembers:NO
                                         supportsNotificationsForThreads:supportsNotificationsForThreads]);
                }
            }];
        }
        else
        {
            completion([self syncFilterWithLazyLoadOfRoomMembers:NO supportsNotificationsForThreads:supportsNotificationsForThreads]);
        }
    };

    [mxSession supportedMatrixVersions:^(MXMatrixVersions *matrixVersions) {
        buildSyncFilter(matrixVersions);
    } failure:^(NSError *error) {
        MXLogWarning(@"[MXAccount] buildSyncFilter: failed to get supported versions: %@", error);
        buildSyncFilter(nil);
    }];
}

/**
 Compute the sync filter to use according to the device screen size.

 @param syncWithLazyLoadOfRoomMembers enable LL support.
 @return the sync filter to use.
 */
- (MXFilterJSONModel *)syncFilterWithLazyLoadOfRoomMembers:(BOOL)syncWithLazyLoadOfRoomMembers supportsNotificationsForThreads:(BOOL)supportsNotificationsForThreads
{
    MXFilterJSONModel *syncFilter;
    NSUInteger limit = 10;
    
    // Define a message limit for /sync requests that is high enough so that
    // a full page of room messages can be displayed without an additional
    // server request.

    // This limit value depends on the device screen size. So, the rough rule is:
    //    - use 10 for small phones (5S/SE)
    //    - use 15 for phones (6/6S/7/8)
    //    - use 20 for phablets (.Plus/X/XR/XS/XSMax)
    //    - use 30 for iPads
    UIUserInterfaceIdiom userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        CGFloat screenHeight = [[UIScreen mainScreen] nativeBounds].size.height;
        if (screenHeight == 1334)   // 6/6S/7/8 screen height
        {
            limit = 15;
        }
        else if (screenHeight > 1334)
        {
            limit = 20;
        }
    }
    else if (userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        limit = 30;
    }
    
    // Set that limit in the filter
    if (syncWithLazyLoadOfRoomMembers)
    {
        syncFilter = [MXFilterJSONModel syncFilterForLazyLoadingWithMessageLimit:limit unreadThreadNotifications:supportsNotificationsForThreads];
    }
    else
    {
        syncFilter = [MXFilterJSONModel syncFilterWithMessageLimit:limit unreadThreadNotifications:supportsNotificationsForThreads];
    }

    // TODO: We could extend the filter to match other settings (self.showAllEventsInRoomHistory,
    // self.eventsFilterForMessages, etc).

    return syncFilter;
}


/**
 Check the sync filter we want to use is compatible with the one previously used.

 @param syncFilter the sync filter to use.
 @param completion the block called to indicated the compatibility.
 */
- (void)checkSyncFilterCompatibility:(MXFilterJSONModel*)syncFilter completion:(void (^)(BOOL compatible))completion
{
    // There is no compatibility issue if no /sync was done before
    if (!mxSession.store.eventStreamToken)
    {
        completion(YES);
    }

    // Check the filter we want to use is compatible with the one previously used
    else if (!syncFilter && !mxSession.syncFilterId)
    {
        // A nil filter implies a nil mxSession.syncFilterId. So, there is no filter change
        completion(YES);
    }
    else if (!syncFilter || !mxSession.syncFilterId)
    {
        // Change from no filter with using a filter or vice-versa. So, there is a filter change
        MXLogDebug(@"[MXKAccount] checkSyncFilterCompatibility: Incompatible filter. New or old is nil. mxSession.syncFilterId: %@ - syncFilter: %@",
              mxSession.syncFilterId, syncFilter.JSONDictionary);
        completion(NO);
    }
    else if (!mxSession.store.allFilterIds.count)
    {
        MXLogDebug(@"[MXKAccount] There are no filters stored in this session, proceed as if no /sync was done before");
        completion(YES);
    }
    else
    {
        // Check the filter is the one previously set
        // It must be already in the store
        MXWeakify(self);
        [mxSession.store filterIdForFilter:syncFilter success:^(NSString * _Nullable filterId) {
            MXStrongifyAndReturnIfNil(self);

            // Note: We could be more tolerant here
            // We could accept filter hot change if the change is limited to the `limit` filter value
            // But we do not have this requirement yet
            BOOL compatible = [filterId isEqualToString:self.mxSession.syncFilterId];
            if (!compatible)
            {
                MXLogDebug(@"[MXKAccount] checkSyncFilterCompatibility: Incompatible filter ids. mxSession.syncFilterId: %@ -  store.filterId: %@ - syncFilter: %@",
                      self.mxSession.syncFilterId, filterId, syncFilter.JSONDictionary);
            }
            completion(compatible);

        } failure:^(NSError * _Nullable error) {
            // Should never happen
            completion(NO);
        }];
    }
}


#pragma mark - Identity server updates

- (void)registerAccountDataDidChangeIdentityServerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountDataDidChangeIdentityServerNotification:) name:kMXSessionAccountDataDidChangeIdentityServerNotification object:nil];
}

- (void)handleAccountDataDidChangeIdentityServerNotification:(NSNotification*)notification
{
    MXSession *mxSession = notification.object;
    if (mxSession == self.mxSession)
    {
        if (![self.mxCredentials.identityServer isEqualToString:self.mxSession.accountDataIdentityServer])
        {
            _identityServerURL = self.mxSession.accountDataIdentityServer;
            self.mxCredentials.identityServer = _identityServerURL;
            self.mxCredentials.identityServerAccessToken = nil;

            // Archive updated field
            [[MXKAccountManager sharedManager] saveAccounts];
        }
    }
}


#pragma mark - Identity server Access Token updates

- (void)identityService:(MXIdentityService *)identityService didUpdateAccessToken:(NSString *)accessToken
{
    self.mxCredentials.identityServerAccessToken = accessToken;
}

- (void)registerIdentityServiceDidChangeAccessTokenNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityServiceDidChangeAccessTokenNotification:) name:MXIdentityServiceDidChangeAccessTokenNotification object:nil];
}

- (void)handleIdentityServiceDidChangeAccessTokenNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSString *userId = userInfo[MXIdentityServiceNotificationUserIdKey];
    NSString *identityServer = userInfo[MXIdentityServiceNotificationIdentityServerKey];
    NSString *accessToken = userInfo[MXIdentityServiceNotificationAccessTokenKey];
    
    if (userId && identityServer && accessToken && [self.mxCredentials.identityServer isEqualToString:identityServer])
    {
        self.mxCredentials.identityServerAccessToken = accessToken;

        // Archive updated field
        [[MXKAccountManager sharedManager] saveAccounts];
    }
}

#pragma mark - Presence

- (void)setPreferredSyncPresence:(MXPresence)preferredSyncPresence
{
    [super setPreferredSyncPresence:preferredSyncPresence];
    
    if (self.mxSession)
    {
        self.mxSession.preferredSyncPresence = preferredSyncPresence;
        [self setUserPresence:preferredSyncPresence andStatusMessage:nil completion:nil];
    }
    
    // Archive updated field
    [[MXKAccountManager sharedManager] saveAccounts];
}

@end
