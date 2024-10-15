/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "MatrixKit.h"

@interface RageShakeManager : NSObject <MXKResponderRageShaking>

+ (id)sharedManager;

/**
 Prompt user to report a crash. The alert is presented by the provided view controller.
 
 @param viewController the view controller which presents the alert
 */
- (void)promptCrashReportInViewController:(UIViewController*)viewController;

@end
