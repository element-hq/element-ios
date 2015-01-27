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

extern NSString *const kMatrixSDKHandlerUnsupportedMessagePrefix;

typedef enum : NSUInteger {
    MatrixSDKHandlerStatusLoggedOut = 0,
    MatrixSDKHandlerStatusLogged,
    MatrixSDKHandlerStatusStoreDataReady,
    MatrixSDKHandlerStatusServerSyncDone
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

// The type of events to display
@property (strong, nonatomic) NSArray *eventsFilterForMessages;

// Matrix user's settings
@property (nonatomic) MXPresence userPresence;

@property (nonatomic,readonly) MatrixSDKHandlerStatus status;
@property (nonatomic,readonly) BOOL isResumeDone;
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
- (void)forceInitialSync:(BOOL)clearCache;

- (void)enableInAppNotifications:(BOOL)isEnabled;

- (BOOL)isSupportedAttachment:(MXEvent*)event;
- (BOOL)isEmote:(MXEvent*)event;

// return a MatrixIDs list of 1:1 room members
- (NSArray*)oneToOneRoomMemberMatrixIDs;

// create a private one to one chat room
- (void)createPrivateOneToOneRoomWith:(NSString*)otherMatrixID;

// Return the suitable url to display the content thumbnail into the provided view size
// Note: the provided view size is supposed in points, this method will convert this size in pixels by considering screen scale
- (NSString*)thumbnailURLForContent:(NSString*)contentURI inViewSize:(CGSize)viewSize withMethod:(MXThumbnailingMethod)thumbnailingMethod;

// Note: the room state expected by the 3 following methods is the room state right before handling the event
- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
- (NSString*)displayTextForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState inSubtitleMode:(BOOL)isSubtitle;

// search if a 1:1 conversation has been started with this member
- (NSString*)getRoomStartedWithMember:(MXRoomMember*)roomMember;

// user power level in a dedicated room
- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room;

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence;

// return YES if the text contains a bing word
- (BOOL)containsBingWord:(NSString*)text;

@end
