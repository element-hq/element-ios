// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
#import <MatrixSDK/MatrixSDK.h>

@class MXKAccountData;

@interface MXKAccountData : NSObject <NSCoding> {
    
@protected MXCredentials *_mxCredentials;
@protected NSString *_identityServerURL;
@protected NSString *_antivirusServerURL;
@protected NSString *_pushGatewayURL;
@protected MXDevice *_device;
@protected BOOL _disabled;
@protected BOOL _enableInAppNotifications;
@protected BOOL _warnedAboutEncryption;
@protected NSMutableDictionary<NSString *, id<NSCoding>> *_others;
@protected NSArray<MXThirdPartyIdentifier *> *_threePIDs;
@protected BOOL _isSoftLogout;
@protected BOOL _hasPusherForPushNotifications;
@protected BOOL _hasPusherForPushKitNotifications;
@protected MXPresence _preferredSyncPresence;
}

/**
 The account's credentials: homeserver, access token, user id.
 */
@property (nonatomic, readonly, nonnull) MXCredentials *mxCredentials;

/**
 The identity server URL.
 */
@property (nonatomic, nonnull) NSString *identityServerURL;

/**
 The antivirus server URL, if any (nil by default).
 Set a non-null url to configure the antivirus scanner use.
 */
@property (nonatomic, nullable) NSString *antivirusServerURL;

/**
 The Push Gateway URL used to send event notifications to (nil by default).
 This URL should be over HTTPS and never over HTTP.
 */
@property (nonatomic, nullable) NSString *pushGatewayURL;

/**
 The 3PIDs linked to this account.
 [self load3PIDs] must be called to update the property.
 */
@property (nonatomic, readonly, nullable) NSArray<MXThirdPartyIdentifier *> *threePIDs;

/**
 The account user's device.
 [self loadDeviceInformation] must be called to update the property.
 */
@property (nonatomic, readonly, nullable) MXDevice *device;

/**
 Transient information storage.
 */
@property (nonatomic, strong, readonly, nonnull) NSMutableDictionary<NSString *, id<NSCoding>> *others;

/**
 Flag to indicate that an APNS pusher has been set on the homeserver for this device.
 */
@property (nonatomic, readonly) BOOL hasPusherForPushNotifications;

/**
 The Push notification activity (based on PushKit) for this account.
 YES when Push is turned on (locally available and enabled homeserver side).
 */
@property (nonatomic, readonly) BOOL isPushKitNotificationActive;

/**
 Flag to indicate that a PushKit pusher has been set on the homeserver for this device.
 */
@property (nonatomic, readonly) BOOL hasPusherForPushKitNotifications;

/**
 The account's preferred Presence status to share while the application is in foreground.
 Defaults to MXPresenceOnline.
 */
@property (nonatomic) MXPresence preferredSyncPresence;


/**
 Enable In-App notifications based on Remote notifications rules.
 NO by default.
 */
@property (nonatomic) BOOL enableInAppNotifications;

/**
 Disable the account without logging out (NO by default).
 
 A matrix session is automatically opened for the account when this property is toggled from YES to NO.
 The session is closed when this property is set to YES.
 */
@property (nonatomic,getter=isDisabled) BOOL disabled;

/**
 Flag indicating if the end user has been warned about encryption and its limitations.
 */
@property (nonatomic,getter=isWarnedAboutEncryption) BOOL warnedAboutEncryption;

#pragma mark - Soft logout

/**
 Flag to indicate if the account has been logged out by the homeserver admin.
 */
@property (nonatomic, readonly) BOOL isSoftLogout;
@end
