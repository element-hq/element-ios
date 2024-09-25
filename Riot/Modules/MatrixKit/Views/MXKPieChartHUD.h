/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import "MXKView.h"

@interface MXKPieChartHUD : MXKView

+ (MXKPieChartHUD *)showLoadingHudOnView:(UIView *)view WithMessage:(NSString *)message;

- (void)setProgress:(CGFloat)progress;

@end
