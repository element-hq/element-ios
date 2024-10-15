// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

#import <Foundation/Foundation.h>
@import Intents;
@protocol ContactResolving;

NS_ASSUME_NONNULL_BEGIN

@interface SendMessageIntentHandler : NSObject <INSendMessageIntentHandling>

- (instancetype)initWithContactResolver:(id<ContactResolving>)contactResolver;

@end

NS_ASSUME_NONNULL_END
