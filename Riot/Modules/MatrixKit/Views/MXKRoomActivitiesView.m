/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomActivitiesView.h"

@implementation MXKRoomActivitiesView

+ (UINib *)nib
{
    // No 'MXKRoomActivitiesView.xib' has been defined yet
    return nil;
}

+ (instancetype)roomActivitiesView
{
    id instance = nil;
    
    if ([[self class] nib])
    {
        @try {
           instance = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
        }
        @catch (NSException *exception) {
        }
    }
    
    if (!instance)
    {
        instance = [[self alloc] initWithFrame:CGRectZero];
    }
 
    return instance;
}

- (void)destroy
{
    _delegate = nil;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

@end
