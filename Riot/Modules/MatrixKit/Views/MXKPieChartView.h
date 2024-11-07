/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKView.h"

@interface MXKPieChartView : MXKView

/**
 The current progress level in [0, 1] range.
 The pie chart is automatically hidden if progress <= 0.
 It is shown for other progress values.
 */
@property (nonatomic) CGFloat progress;

@property (strong, nonatomic) UIColor* progressColor;
@property (strong, nonatomic) UIColor* unprogressColor;

@end

