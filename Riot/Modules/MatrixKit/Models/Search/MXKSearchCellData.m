/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKSearchCellData.h"

#import "MXKSearchDataSource.h"


@implementation MXKSearchCellData
@synthesize roomId, senderDisplayName;
@synthesize searchResult, title, message, date, shouldShowRoomDisplayName, roomDisplayName, attachment, isAttachmentWithThumbnail, attachmentIcon;

- (instancetype)initWithSearchResult:(MXSearchResult *)searchResult2 andSearchDataSource:(MXKSearchDataSource *)searchDataSource
{
    self = [super init];
    if (self)
    {
        searchResult = searchResult2;

        if (searchDataSource.roomEventFilter.rooms.count == 1)
        {
            // We are displaying a search within a room
            // As title, display the user id
            title = searchResult.result.sender;
            
            roomId = searchDataSource.roomEventFilter.rooms[0];
        }
        else
        {
            // We are displaying a search over all user's rooms
            // As title, display the room name of this search result
            MXRoom *room = [searchDataSource.mxSession roomWithRoomId:searchResult.result.roomId];
            if (room)
            {
                title = room.summary.displayName;
            }
            else
            {
                title = searchResult.result.roomId;
            }
        }

        date = [searchDataSource.eventFormatter dateStringFromEvent:searchResult.result withTime:YES];

        // Code from [MXEventFormatter stringFromEvent] for the particular case of a text message
        message = [searchResult.result.content[kMXMessageBodyKey] isKindOfClass:[NSString class]] ? searchResult.result.content[kMXMessageBodyKey] : nil;
    }
    return self;
}

+ (void)cellDataWithSearchResult:(MXSearchResult *)searchResult andSearchDataSource:(MXKSearchDataSource *)searchDataSource onComplete:(void (^)(id<MXKSearchCellDataStoring>))onComplete
{
    onComplete([[self alloc] initWithSearchResult:searchResult andSearchDataSource:searchDataSource]);
}

@end
