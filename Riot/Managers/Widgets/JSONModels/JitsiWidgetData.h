/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
