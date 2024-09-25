/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRecentTableViewCell.h"

#import "MXKSessionRecentsDataSource.h"

@implementation MXKRecentTableViewCell
@synthesize delegate;

#pragma mark - Class methods

- (void)render:(MXKCellData *)cellData
{
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        
        // Report computed values as is
        _roomTitle.text = roomCellData.roomDisplayname;
        _lastEventDate.text = roomCellData.lastEventDate;
        
        // Manage lastEventAttributedTextMessage optional property
        if ([roomCellData respondsToSelector:@selector(lastEventAttributedTextMessage)])
        {
            _lastEventDescription.attributedText = roomCellData.lastEventAttributedTextMessage;
        }
        else
        {
            _lastEventDescription.text = roomCellData.lastEventTextMessage;
        }
        
        // Set in bold public room name
        if ([roomCellData.roomSummary.joinRule isEqualToString:kMXRoomJoinRulePublic])
        {
            _roomTitle.font = [UIFont boldSystemFontOfSize:20];
        }
        else
        {
            _roomTitle.font = [UIFont systemFontOfSize:19];
        }
        
        // Set background color and unread count
        if (roomCellData.hasUnread)
        {
            if (0 < roomCellData.highlightCount)
            {
                self.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:1 alpha:1.0];
            }
            else
            {
                self.backgroundColor = [UIColor colorWithRed:1 green:0.9 blue:0.9 alpha:1.0];
            }
        }
        else
        {
            self.backgroundColor = [UIColor clearColor];
        }
        
    }
    else
    {
        _lastEventDescription.text = @"";
    }
}

- (MXKCellData*)renderedCellData
{
    return roomCellData;
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 70;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    roomCellData = nil;
}

@end
