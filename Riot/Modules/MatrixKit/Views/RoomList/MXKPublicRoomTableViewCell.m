/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPublicRoomTableViewCell.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@implementation MXKPublicRoomTableViewCell

- (void)render:(MXPublicRoom*)publicRoom
{
    // Check whether this public room has topic
    if (publicRoom.topic)
    {
        _roomTopic.hidden = NO;
        _roomTopic.text = [MXTools stripNewlineCharacters:publicRoom.topic];
    }
    else
    {
        _roomTopic.hidden = YES;
    }
    
    // Set room display name
    _roomDisplayName.text = [publicRoom displayname];
    
    // Set member count
    if (publicRoom.numJoinedMembers > 1)
    {
        _memberCount.text = [VectorL10n numMembersOther:@(publicRoom.numJoinedMembers).stringValue];
    }
    else if (publicRoom.numJoinedMembers == 1)
    {
        _memberCount.text = [VectorL10n numMembersOne:@(1).stringValue];
    }
    else
    {
        _memberCount.text = nil;
    }
}

- (void)setHighlightedPublicRoom:(BOOL)highlightedPublicRoom
{
    // Highlight?
    if (highlightedPublicRoom)
    {
        _roomDisplayName.font = [UIFont boldSystemFontOfSize:20];
        _roomTopic.font = [UIFont boldSystemFontOfSize:17];
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
    }
    else
    {
        _roomDisplayName.font = [UIFont systemFontOfSize:19];
        _roomTopic.font = [UIFont systemFontOfSize:16];
        self.backgroundColor = [UIColor clearColor];
    }
    _highlightedPublicRoom = highlightedPublicRoom;
}

@end

