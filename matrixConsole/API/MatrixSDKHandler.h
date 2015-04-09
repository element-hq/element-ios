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

extern NSString *const kMatrixSDKHandlerUnsupportedEventDescriptionPrefix;

typedef enum : NSUInteger {
    MatrixSDKHandlerStatusLoggedOut = 0,
    MatrixSDKHandlerStatusLogged,
    MatrixSDKHandlerStatusStoreDataReady,
    MatrixSDKHandlerStatusInitialServerSyncInProgress,
    MatrixSDKHandlerStatusServerSyncDone,
    MatrixSDKHandlerStatusPaused
} MatrixSDKHandlerStatus;

@interface MatrixSDKHandler : NSObject

@property (strong, nonatomic) dispatch_queue_t processingQueue;

@property (strong, nonatomic) MXRestClient *mxRestClient;
@property (strong, nonatomic) MXSession *mxSession;

@property (strong, nonatomic) NSString *homeServerURL;
@property (strong, nonatomic) NSString *homeServer;
@property (strong, nonatomic) NSString *userLogin;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic, readonly) NSString *localPartFromUserId;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *identityServerURL;

// The type of events to display
@property (strong, nonatomic) NSArray *eventsFilterForMessages;

// Matrix user's settings
@property (nonatomic) MXPresence userPresence;

@property (nonatomic,readonly) MatrixSDKHandlerStatus status;
@property (nonatomic,readonly) BOOL isActivityInProgress;
// return the MX cache size in bytes
@property (nonatomic,readonly) NSUInteger MXCacheSize;
// return the sum of the caches (MX cache + media cache ...) in bytes
@property (nonatomic,readonly) NSUInteger cachesSize;
// defines the min allow cache size in bytes
@property (nonatomic,readonly) NSUInteger minCachesSize;
// defines the current max caches size in bytes
@property (nonatomic,readwrite) NSUInteger currentMaxCachesSize;
// defines the max allowed caches size in bytes
@property (nonatomic,readonly) NSUInteger maxAllowedCachesSize;

+ (MatrixSDKHandler *)sharedHandler;

- (void)pauseInBackgroundTask;
- (void)resume;
- (void)logout;

// Flush and restore Matrix data
- (void)reload:(BOOL)clearCache;

- (void)enableInAppNotifications:(BOOL)isEnabled;

// return a userIds list of 1:1 room members
- (NSArray*)oneToOneRoomMemberIDs;

// Searches if a private OneToOne room has been started with this user
// Returns the room ID (nil if not found)
- (NSString*)privateOneToOneRoomIdWithUserId:(NSString*)userId;
// Reopens an existing private OneToOne room with this userId or creates a new one (if it doesn't exist)
- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId;

// Enables inApp notifications for a dedicated room if they were disabled
- (void)restoreInAppNotificationsForRoomId:(NSString*)roomID;

// Stores the current text message partially typed in text input before leaving a room (use nil to reset the current value)
- (void)storePartialTextMessage:(NSString*)textMessage forRoomId:(NSString*)roomId;
// Returns the current partial message stored for this room (nil if none)
- (NSString*)partialTextMessageForRoomId:(NSString*)roomId;

// user power level in a dedicated room
- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room;

- (BOOL)isSupportedAttachment:(MXEvent*)event;
- (BOOL)isEmote:(MXEvent*)event;
// Note: the room state expected by the 3 following methods is the room state right before handling the event
- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
- (NSString*)displayTextForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState inSubtitleMode:(BOOL)isSubtitle;

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence;

// return YES if the text contains a bing word
- (BOOL)containsBingWord:(NSString*)text;

@end
