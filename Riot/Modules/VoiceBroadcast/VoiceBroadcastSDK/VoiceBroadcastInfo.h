// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <MatrixSDK/MatrixSDK.h>

#import "MXJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VoiceBroadcastInfo : MXJSONModel

/// The voice broadcast state (started - paused - resumed - stopped).
@property (nonatomic) NSString *state;

/// The length of the voice chunks in seconds. Only required on the started state event.
@property (nonatomic) NSInteger chunkLength;

///  The event id of the started voice broadcast info state event.
@property (nonatomic, strong, nullable) NSString* eventId;

/// The event used to build the MXBeaconInfo.
@property (nonatomic, readonly, nullable) MXEvent *originalEvent;

- (instancetype)initWithState:(NSString *)state
                  chunkLength:(NSInteger)chunkLength
                      eventId:(NSString *)eventId;

@end

NS_ASSUME_NONNULL_END
