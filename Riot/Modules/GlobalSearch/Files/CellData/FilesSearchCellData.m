/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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
            roomDisplayName = room.summary.displayname;
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
