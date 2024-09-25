/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2018 New Vector Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKAccount.h"

/**
 Posted when the user logged in with a matrix account.
 The notification object is the new added account.
 */
extern NSString *const kMXKAccountManagerDidAddAccountNotification;

/**
 Posted when an existing account is logged out.
 The notification object is the removed account.
 */
extern NSString *const kMXKAccountManagerDidRemoveAccountNotification;

/**
 Posted when an existing account is soft logged out.
 The notification object is the account.
 */
extern NSString *const kMXKAccountManagerDidSoftlogoutAccountNotification;

/**
 Used to identify the type of data when requesting MXKeyProvider
 */
extern NSString *const MXKAccountManagerDataType;

/**
 `MXKAccountManager` manages a pool of `MXKAccount` instances.
 */
@interface MXKAccountManager : NSObject

/// Flag indicating that saving accounts enabled. Defaults to `YES`.
@property (nonatomic, assign, getter=isSavingAccountsEnabled) BOOL savingAccountsEnabled;

/**
 The class of store used to open matrix session for the accounts. This class must be conformed to MXStore protocol.
 By default this class is MXFileStore.
 */
@property (nonatomic) Class storeClass;

/**
 List of all available accounts (enabled and disabled).
 */
@property (nonatomic, readonly) NSArray<MXKAccount *> *accounts;

/**
 List of active accounts (only enabled accounts)
 */
@property (nonatomic, readonly) NSArray<MXKAccount *> *activeAccounts;

/**
 The device token used for Apple Push Notification Service registration.
 */
@property (nonatomic, copy) NSData *apnsDeviceToken;

/**
 The APNS status: YES when app is registered for remote notif, and device token is known.
 */
@property (nonatomic) BOOL isAPNSAvailable;

/**
 The device token used for Push notifications registration (PushKit support).
 */
@property (nonatomic, copy, readonly) NSData *pushDeviceToken;

/**
 The current options of the Push notifications based on PushKit.
 */
@property (nonatomic, copy, readonly) NSDictionary *pushOptions;

/**
 Set the push token and the potential push options.
 For example, for clients that want to go & fetch the body of the event themselves anyway,
 the key-value `format: event_id_only` may be used in `pushOptions` dictionary to tell the
 HTTP pusher to send just the event_id of the event it's notifying about, the room id and
 the notification counts.
 
 @param pushDeviceToken the push token.
 @param pushOptions dictionary of the push options (may be nil).
 */
- (void)setPushDeviceToken:(NSData *)pushDeviceToken withPushOptions:(NSDictionary *)pushOptions;

/**
 The PushKit status: YES when app is registered for push notif, and push token is known.
 */
@property (nonatomic) BOOL isPushAvailable;

/**
 Retrieve the MXKAccounts manager.
 
 @return the MXKAccounts manager.
 */
+ (MXKAccountManager *)sharedManager;

+ (MXKAccountManager *)sharedManagerWithReload:(BOOL)reload;

/**
 Check for each enabled account if a matrix session is already opened.
 Open a matrix session for each enabled account which doesn't have a session.
 The developper must set 'storeClass' before the first call of this method 
 if the default class is not suitable.
 */
- (void)prepareSessionForActiveAccounts;

/**
 Save a snapshot of the current accounts.
 */
- (void)saveAccounts;

/**
 Add an account and save the new account list. Optionally a matrix session may be opened for the provided account.
 
 @param account a matrix account.
 @param openSession YES to open a matrix session (this value is ignored if the account is disabled).
 */
- (void)addAccount:(MXKAccount *)account andOpenSession:(BOOL)openSession;

/**
 Remove the provided account and save the new account list. This method is used in case of logout.
 
 @note equivalent to `removeAccount:sendLogoutRequest:completion:` method with `sendLogoutRequest` parameter to YES
 
 @param account a matrix account.
 @param completion the block to execute at the end of the operation.
 */
- (void)removeAccount:(MXKAccount *)account completion:(void (^)(void))completion;


/**
 Remove the provided account and save the new account list. This method is used in case of logout or account deactivation.
 
 @param account a matrix account.
 @param sendLogoutRequest Indicate whether send logout request to homeserver.
 @param completion the block to execute at the end of the operation.
 */
- (void)removeAccount:(MXKAccount*)account
    sendLogoutRequest:(BOOL)sendLogoutRequest
           completion:(void (^)(void))completion;

/**
 Log out and remove all the existing accounts
 
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutWithCompletion:(void (^)(void))completion;

/**
 Soft logout an account.

 @param account a matrix account.
 */
- (void)softLogout:(MXKAccount*)account;

/**
 Hydrate an existing account by using the credentials provided.

 This updates account credentials and restarts the account session

 If the credentials belong to a different user from the account already stored,
 the old account will be cleared automatically.

 @param account a matrix account.
 @param credentials the new credentials.
 */
- (void)hydrateAccount:(MXKAccount*)account withCredentials:(MXCredentials*)credentials;

/**
 Retrieve the account for a user id.
 
 @param userId the user id.
 @return the user's account (nil if no account exist).
 */
- (MXKAccount *)accountForUserId:(NSString *)userId;

/**
 Retrieve an account that knows the room with the passed id or alias.
 
 Note: The method is not accurate as it returns the first account that matches.

 @param roomIdOrAlias the room id or alias.
 @return the user's account. Nil if no account matches.
 */
- (MXKAccount *)accountKnowingRoomWithRoomIdOrAlias:(NSString *)roomIdOrAlias;

/**
 Retrieve an account that knows the user with the passed id.

 Note: The method is not accurate as it returns the first account that matches.

 @param userId the user id.
 @return the user's account. Nil if no account matches.
 */
- (MXKAccount *)accountKnowingUserWithUserId:(NSString *)userId;

- (void)readAndWriteCredentials:(void (^)(NSArray<MXCredentials*> * _Nullable readData,  void (^completion)(BOOL didUpdateCredentials)))readAnWriteHandler;

@end
