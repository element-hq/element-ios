/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C

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

#import <MatrixSDK/MatrixSDK.h>
#import "MXKAccountData.h"

@class MXKAccount;

/**
 Posted when account user information (display name, picture, presence) has been updated.
 The notification object is the matrix user id of the account.
 */
extern NSString *const kMXKAccountUserInfoDidChangeNotification;

/**
 Posted when the activity of the Apple Push Notification Service has been changed.
 The notification object is the matrix user id of the account.
 */
extern NSString *const kMXKAccountAPNSActivityDidChangeNotification;

/**
 Posted when the activity of the Push notification based on PushKit has been changed.
 The notification object is the matrix user id of the account.
 */
extern NSString *const kMXKAccountPushKitActivityDidChangeNotification;

/**
 MXKAccount error domain
 */
extern NSString *const kMXKAccountErrorDomain;

/**
 Block called when a certificate change is observed during authentication challenge from a server.
 
 @param mxAccount the account concerned by this certificate change.
 @param certificate the server certificate to evaluate.
 @return YES to accept/trust this certificate, NO to cancel/ignore it.
 */
typedef BOOL (^MXKAccountOnCertificateChange)(MXKAccount *mxAccount, NSData *certificate);

/**
 `MXKAccount` object contains the credentials of a logged matrix user. It is used to handle matrix
 session and presence for this user.
 */
@interface MXKAccount : MXKAccountData

/**
 The matrix REST client used to make matrix API requests.
 */
@property (nonatomic, readonly) MXRestClient *mxRestClient;

/**
 The matrix session opened with the account (nil by default).
 */
@property (nonatomic, readonly) MXSession *mxSession;

/**
 The account user's display name (nil by default, available if matrix session `mxSession` is opened).
 The notification `kMXKAccountUserInfoDidChangeNotification` is posted in case of change of this property.
 */
@property (nonatomic, readonly) NSString *userDisplayName;

/**
 The account user's avatar url (nil by default, available if matrix session `mxSession` is opened).
 The notification `kMXKAccountUserInfoDidChangeNotification` is posted in case of change of this property.
 */
@property (nonatomic, readonly) NSString *userAvatarUrl;

/**
 The account display name based on user id and user displayname (if any).
 */
@property (nonatomic, readonly) NSString *fullDisplayName;

/**
 The email addresses linked to this account.
 This is a subset of self.threePIDs.
 */
@property (nonatomic, readonly) NSArray<NSString *> *linkedEmails;

/**
 The phone numbers linked to this account.
 This is a subset of self.threePIDs.
 */
@property (nonatomic, readonly) NSArray<NSString *> *linkedPhoneNumbers;

/**
 The account user's presence (`MXPresenceUnknown` by default, available if matrix session `mxSession` is opened).
 The notification `kMXKAccountUserInfoDidChangeNotification` is posted in case of change of this property.      
 */
@property (nonatomic, readonly) MXPresence userPresence;

/**
 The account user's tint color: a unique color fixed by the user id. This tint color may be used to highlight
 rooms which belong to this account's user.
 */
@property (nonatomic, readonly) UIColor *userTintColor;

/**
 The Apple Push Notification Service activity for this account. YES when APNS is turned on (locally available and synced with server).
 */
@property (nonatomic, readonly) BOOL pushNotificationServiceIsActive;

/**
 Enable Push notification based on Apple Push Notification Service (APNS).

 This method creates or removes a pusher on the homeserver.

 @param enable YES to enable it.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)enablePushNotifications:(BOOL)enable
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *))failure;

/**
 The Push notification activity (based on PushKit) for this account.
 YES when Push is turned on (locally available and enabled homeserver side).
 */
@property (nonatomic, readonly) BOOL isPushKitNotificationActive;

/**
 Enable Push notification based on PushKit.

 This method creates or removes a pusher on the homeserver.

 @param enable YES to enable it.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)enablePushKitNotifications:(BOOL)enable
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *))failure;

/**
 Manage the online presence event.
 
 The presence event must not be sent if the application is launched by a push notification.
 */
@property (nonatomic) BOOL hideUserPresence;

/**
 Register the MXKAccountOnCertificateChange block that will be used to handle certificate change during account use.
 This block is nil by default, any new certificate is ignored/untrusted (this will abort the connection to the server).
 
 @param onCertificateChangeBlock the block that will be used to handle certificate change.
 */
+ (void)registerOnCertificateChangeBlock:(MXKAccountOnCertificateChange)onCertificateChangeBlock;

/**
 Get the color code related to a specific presence.
 
 @param presence a user presence
 @return color defined for the provided presence (nil if no color is defined).
 */
+ (UIColor*)presenceColor:(MXPresence)presence;

/**
 Init `MXKAccount` instance with credentials. No matrix session is opened by default.
 
 @param credentials user's credentials
 */
- (nonnull instancetype)initWithCredentials:(MXCredentials*)credentials;

/**
 Create a matrix session based on the provided store.
 When store data is ready, the live stream is automatically launched by synchronising the session with the server.
 
 In case of failure during server sync, the method is reiterated until the data is up-to-date with the server.
 This loop is stopped if you call [MXCAccount closeSession:], it is suspended if you call [MXCAccount pauseInBackgroundTask].
 
 @param store the store to use for the session.
 */
-(void)openSessionWithStore:(id<MXStore>)store;

/**
 Close the matrix session.
 
 @param clearStore set YES to delete all store data.
 */
- (void)closeSession:(BOOL)clearStore;

/**
 Invalidate the access token, close the matrix session and delete all store data.
 
 @note This method is equivalent to `logoutSendingServerRequest:completion:` with `sendLogoutServerRequest` parameter to YES
 
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 */
- (void)logout:(void (^)(void))completion;

/**
 Invalidate the access token, close the matrix session and delete all store data.
 
 @param sendLogoutServerRequest indicate to send logout request to homeserver.
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 */
- (void)logoutSendingServerRequest:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(void))completion;


#pragma mark - Soft logout

/**
 Soft logout the account.

 The matix session is stopped but the data is kept.
 */
- (void)softLogout;

/**
 Hydrate the account using the credentials provided.

 @param credentials the new credentials.
*/
- (void)hydrateWithCredentials:(MXCredentials*)credentials;

/**
 Pause the current matrix session.
 
 @warning: This matrix session is paused without using background task if no background mode handler
 is set in the MXSDKOptions sharedInstance (see `backgroundModeHandler`).
 */
- (void)pauseInBackgroundTask;

/**
 Perform a background sync by keeping the user offline.
 
 @warning: This operation failed when no background mode handler is set in the
 MXSDKOptions sharedInstance (see `backgroundModeHandler`).
 
 @param timeout the timeout in milliseconds.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)backgroundSync:(unsigned int)timeout success:(void (^)(void))success failure:(void (^)(NSError *))failure;

/**
 Resume the current matrix session.
 */
- (void)resume;

/**
 Close the potential matrix session and open a new one if the account is not disabled.
 
 @param clearCache set YES to delete all store data.
 */
- (void)reload:(BOOL)clearCache;

/**
 Set the display name of the account user.
 
 @param displayname the new display name.
 
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)setUserDisplayName:(NSString*)displayname success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Set the avatar url of the account user.
 
 @param avatarUrl the new avatar url.
 
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)setUserAvatarUrl:(NSString*)avatarUrl success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Update the account password.
 
 @param oldPassword the old password.
 @param newPassword the new password.
 @param logoutDevices flag to logout from all devices.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)changePassword:(NSString*)oldPassword
                  with:(NSString*)newPassword
         logoutDevices:(BOOL)logoutDevices
               success:(void (^)(void))success
               failure:(void (^)(NSError *error))failure;

/**
 Load the 3PIDs linked to this account.
 This method must be called to refresh self.threePIDs and self.linkedEmails.

 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)load3PIDs:(void (^)(void))success failure:(void (^)(NSError *error))failure;

/**
 Loads the pusher instance linked to this account.
 This method must be called to refresh self.pushNotificationServiceIsActive

 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)loadCurrentPusher:(nullable void (^)(void))success failure:(nullable void (^)(NSError *error))failure;

/**
 Load the current device information for this account.
 This method must be called to refresh self.device.
 
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)loadDeviceInformation:(void (^)(void))success failure:(void (^)(NSError *error))failure;

#pragma mark - Push notification listeners
/**
 Register a listener to push notifications for the account's session.
 
 The listener will be called when a push rule matches a live event.
 Note: only one listener is supported. Potential existing listener is removed.
 
 You may use `[MXCAccount updateNotificationListenerForRoomId:]` to disable/enable all notifications from a specific room.
 
 @param onNotification the block that will be called once a live event matches a push rule.
 */
- (void)listenToNotifications:(MXOnNotification)onNotification;

/**
 Unregister the listener.
 */
- (void)removeNotificationListener;

/**
 Update the listener to ignore or restore notifications from a specific room.
 
 @param roomID the id of the concerned room.
 @param isIgnored YES to disable notifications from the specified room. NO to restore them.
 */
- (void)updateNotificationListenerForRoomId:(NSString*)roomID ignore:(BOOL)isIgnored;

#pragma mark - Crypto
/**
 Delete the device id.

 Call this method when the current device id cannot be used anymore.
 */
- (void)resetDeviceId;

#pragma mark - Sync filter

/**
 Call this method at an appropriate time to attempt dehydrating to a new backup device
 */
- (void)attemptDeviceDehydrationWithKeyData:(NSData *)keyData
                                    success:(void (^)(void))success
                                    failure:(void (^)(NSError *error))failure;

/**
 Handle unauthenticated errors from  the server triggering hard/soft logouts as appropriate.
 */
- (void)handleUnauthenticatedWithError:(MXError *)error isSoftLogout:(BOOL)isSoftLogout isRefreshTokenAuth:(BOOL)isRefreshTokenAuth andCompletion:(void (^)(void))completion;
@end
