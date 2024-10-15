/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "FilesSearchCellData.h"

#import "GeneratedInterface-Swift.h"

@implementation FilesSearchCellData
@synthesize roomId, senderDisplayName;
@synthesize searchResult, title, message, date, shouldShowRoomDisplayName, roomDisplayName, attachment, isAttachmentWithThumbnail, attachmentIcon;

- (instancetype)initWithSearchResult:(MXSearchResult *)searchResult2 andSearchDataSource:(MXKSearchDataSource *)searchDataSource2
{
    self = [super init];
    if (self)
    {
        searchResult = searchResult2;
        searchDataSource = searchDataSource2;
        
        MXEvent *event = searchResult.result;

        roomId = event.roomId;
        
        // Title is here the file name stored in event body
        title = [event.content[kMXMessageBodyKey] isKindOfClass:[NSString class]] ? event.content[kMXMessageBodyKey] : nil;
        
        // Check attachment if any
        if ([searchDataSource.eventFormatter isSupportedAttachment:event])
        {
            // Note: event.eventType may be equal here to MXEventTypeRoomMessage or MXEventTypeSticker
            attachment = [[MXKAttachment alloc] initWithEvent:event andMediaManager:searchDataSource.mxSession.mediaManager];
        }
        
        // Append the file size if any
        if (attachment.contentInfo[@"size"])
        {
            NSInteger size = [attachment.contentInfo[@"size"] integerValue];
            if (size)
            {
                title = [NSString stringWithFormat:@"%@ (%@)", title, [MXTools fileSizeToString:size round:YES]];
            }
        }
        
        date = [searchDataSource.eventFormatter dateStringFromEvent:event withTime:NO];
    }
    return self;
}

+ (void)cellDataWithSearchResult:(MXSearchResult *)searchResult andSearchDataSource:(MXKSearchDataSource *)searchDataSource onComplete:(void (^)(id<MXKSearchCellDataStoring>))onComplete
{
    FilesSearchCellData *cellData = [[self alloc] initWithSearchResult:searchResult andSearchDataSource:searchDataSource];
    if (cellData)
    {
        // Retrieve the sender display name from the current room state
        MXRoom *room = [searchDataSource.mxSession roomWithRoomId:cellData.roomId];
        if (room)
        {
            [room state:^(MXRoomState *roomState) {
                cellData->senderDisplayName = [roomState.members memberName:searchResult.result.sender];
                cellData->message = cellData->senderDisplayName;

                onComplete(cellData);
            }];
        }
        else
        {
            cellData->senderDisplayName = searchResult.result.sender;
            cellData->message = cellData->senderDisplayName;

            onComplete(cellData);
        }
    }
    else
    {
        onComplete(nil);
    }
}

- (void)setShouldShowRoomDisplayName:(BOOL)shouldShowRoomDisplayName2
{
    shouldShowRoomDisplayName = shouldShowRoomDisplayName2;
    
    if (shouldShowRoomDisplayName)
    {
        MXRoom *room = [searchDataSource.mxSession roomWithRoomId:roomId];
        if (room)
        {
            roomDisplayName = room.summary.displayName;
            if (!roomDisplayName.length)
            {
                roomDisplayName = [VectorL10n roomDisplaynameEmptyRoom];
            }
        }
        else
        {
            roomDisplayName = roomId;
        }
        
        message = [NSString stringWithFormat:@"%@ - %@", roomDisplayName, senderDisplayName];
    }
    else
    {
        message = senderDisplayName;
    }
}

- (BOOL)isAttachmentWithThumbnail
{
    return (attachment && (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo || attachment.type == MXKAttachmentTypeSticker));
}

- (UIImage*)attachmentIcon
{
    MXEvent *event = searchResult.result;
    NSString *msgtype;
    MXJSONModelSetString(msgtype, event.content[kMXMessageTypeKey]);
    
    if ([msgtype isEqualToString:kMXMessageTypeImage])
    {
        return AssetImages.filePhotoIcon.image;
    }
    else if ([msgtype isEqualToString:kMXMessageTypeAudio])
    {
        return AssetImages.fileMusicIcon.image;
    }
    else if ([msgtype isEqualToString:kMXMessageTypeVideo])
    {
        return AssetImages.fileVideoIcon.image;
    }
    else if ([msgtype isEqualToString:kMXMessageTypeFile])
    {
        return AssetImages.fileDocIcon.image;
    }
    
    return nil;
}

@end
