// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <MatrixSDK/MatrixSDK.h>

#import "MXJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VoiceBroadcastInfo : MXJSONModel

/// The device id from which the broadcast has been started
@property (nonatomic) NSString *deviceId;

/// The voice broadcast state (started - paused - resumed - stopped).
@property (nonatomic) NSString *state;

/// The length of the voice chunks in seconds. Only required on the started state event.
@property (nonatomic) NSInteger chunkLength;

/// The event id of the started voice broadcast info state event.
@property (nonatomic, strong, nullable) NSString* voiceBroadcastId;

/// The voice broadcast last chunk sequence number.
@property (nonatomic) NSInteger lastChunkSequence;

- (instancetype)initWithDeviceId:(NSString *)deviceId
                           state:(NSString *)state
                     chunkLength:(NSInteger)chunkLength
                voiceBroadcastId:(NSString *)voiceBroadcastId
               lastChunkSequence:(NSInteger)lastChunkSequence;

@end

NS_ASSUME_NONNULL_END
