/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKInterleavedRecentTableViewCell.h"

#import "MXKSessionRecentsDataSource.h"

#import "MXKAccountManager.h"

@implementation MXKInterleavedRecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];

    CAShapeLayer *userFlagMaskLayer = [[CAShapeLayer alloc] init];
    userFlagMaskLayer.frame = _userFlag.bounds;
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(_userFlag.frame.size.width, _userFlag.frame.size.height)];
    [path addLineToPoint:CGPointMake(_userFlag.frame.size.width, 0)];
    [path closePath];
    
    userFlagMaskLayer.path = path.CGPath;
    _userFlag.layer.mask = userFlagMaskLayer;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    // Highlight the room owner by using his tint color.
    if (roomCellData)
    {
        MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:roomCellData.mxSession.myUserId];
        if (account)
        {
            _userFlag.backgroundColor = account.userTintColor;
        }
        else
        {
            _userFlag.backgroundColor = [UIColor clearColor];
        }
    }
}

@end
