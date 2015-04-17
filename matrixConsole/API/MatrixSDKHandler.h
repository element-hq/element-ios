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

#import <MatrixSDK/MatrixSDK.h>

typedef enum : NSUInteger {
    MatrixSDKHandlerStatusLoggedOut = 0,
    MatrixSDKHandlerStatusLogged,
    MatrixSDKHandlerStatusStoreDataReady,
    MatrixSDKHandlerStatusInitialServerSyncInProgress,
    MatrixSDKHandlerStatusServerSyncDone,
    MatrixSDKHandlerStatusPaused
} MatrixSDKHandlerStatus;

@interface MatrixSDKHandler : NSObject

@property (strong, nonatomic) MXRestClient *mxRestClient;
@property (strong, nonatomic) MXSession *mxSession;

@property (strong, nonatomic) NSString *homeServerURL;
@property (strong, nonatomic) NSString *homeServer;
@property (strong, nonatomic) NSString *userLogin;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic, readonly) NSString *localPartFromUserId;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *identityServerURL;

// Matrix user's settings
@property (nonatomic) MXPresence userPresence;

+ (MatrixSDKHandler *)sharedHandler;

- (void)pauseInBackgroundTask;
- (void)resume;
- (void)logout;

// Flush and restore Matrix data
- (void)reload:(BOOL)clearCache;

// Searches if a private OneToOne room has been started with this user
// Returns the room ID (nil if not found)
- (NSString*)privateOneToOneRoomIdWithUserId:(NSString*)userId;
// Reopens an existing private OneToOne room with this userId or creates a new one (if it doesn't exist)
- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId;

// Enables inApp notifications for a dedicated room if they were disabled
- (void)restoreInAppNotificationsForRoomId:(NSString*)roomID;

// user power level in a dedicated room
- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room;

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence;

@end
