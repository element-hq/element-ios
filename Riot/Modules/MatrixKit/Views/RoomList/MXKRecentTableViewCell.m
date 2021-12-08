/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
