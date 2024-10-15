/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKView.h"

@implementation MXKView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self customizeViewRendering];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self customizeViewRendering];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self customizeViewRendering];
}

- (void)customizeViewRendering
{
    // Do nothing by default.
}

@end
