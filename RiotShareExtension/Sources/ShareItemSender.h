// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

#import <UIKit/UIKit.h>

#import "ShareItemSenderProtocol.h"

@class ShareExtensionShareItemProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ShareItemSender : NSObject <ShareItemSenderProtocol>

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                         shareItemProvider:(ShareExtensionShareItemProvider *)shareItemProvider;

@end

NS_ASSUME_NONNULL_END
