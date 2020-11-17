/*
 Copyright 2020 New Vector Ltd
 
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

#import <Foundation/Foundation.h>

#import "MXJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 JitsiWidgetData represents Jitsi widget data according to Matrix Widget API v2
 */
@interface JitsiWidgetData : MXJSONModel

// The domain of the Jitsi server (eg: “jitsi.riot.im”)
@property (nonatomic, nullable) NSString *domain;

// The ID of the Jitsi conference
@property (nonatomic) NSString *conferenceId;

// YES if the Jitsi conference is intended to be an audio-only call
@property (nonatomic) BOOL isAudioOnly;

// Indicate the authentication supported by the Jitsi server if any otherwise nil if there is no authentication supported.
@property (nonatomic, nullable) NSString *authenticationType;

@end

NS_ASSUME_NONNULL_END
