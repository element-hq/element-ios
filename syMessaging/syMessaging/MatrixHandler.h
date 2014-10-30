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

// Presently the SDK is not able to handle correctly the context for the room recently joined
// PATCH: we force initial sync if this is necessary (see TEMPORARY_PATCH_INITIAL_SYNC occurences)
// FIXME: this compilation flag must be removed when SDK will fix the issue
#define TEMPORARY_PATCH_INITIAL_SYNC 1

extern NSString *const kMatrixHandlerUnsupportedMessagePrefix;

@interface MatrixHandler : NSObject

@property (strong, nonatomic) MXHomeServer *mxHomeServer;
@property (strong, nonatomic) MXSession *mxSession;
@property (strong, nonatomic) MXData *mxData;

@property (strong, nonatomic) NSString *homeServerURL;
@property (strong, nonatomic) NSString *homeServer;
@property (strong, nonatomic) NSString *userLogin;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *accessToken;

// Matrix user's settings
@property (strong, nonatomic) NSString *userDisplayName;
@property (strong, nonatomic) NSString *userPictureURL;

@property (nonatomic,readonly) BOOL isLogged;
@property (nonatomic,readonly) BOOL isInitialSyncDone;

+ (MatrixHandler *)sharedHandler;

- (void)logout;

// Flush and restore Matrix data
- (void)forceInitialSync;

- (void)enableEventsNotifications:(BOOL)isEnabled;

- (BOOL)isAttachment:(MXEvent*)message;
- (BOOL)isNotification:(MXEvent*)message;
- (NSString*)displayTextFor:(MXEvent*)message inSubtitleMode:(BOOL)isSubtitle;

@end
