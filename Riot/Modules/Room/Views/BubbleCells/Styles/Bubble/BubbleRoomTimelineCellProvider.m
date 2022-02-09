// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BubbleRoomTimelineCellProvider.h"

#pragma mark - Imports

#pragma mark Text message

// Outgoing

// Clear
#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleWithoutSenderNameBubbleCell.h"

// Encrypted

#import "RoomOutgoingEncryptedTextMsgBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"

#pragma mark Attachment

// Outgoing

// Clear
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"
// Encrypted
#import "RoomOutgoingEncryptedAttachmentBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

#import "GeneratedInterface-Swift.h"

@implementation BubbleRoomTimelineCellProvider

#pragma mark - Registration

- (void)registerCellsForTableView:(UITableView *)tableView
{
    [super registerCellsForTableView:tableView];
    
    [self registerFileWithoutThumbnailCellsForTableView:tableView];
}

- (void)registerIncomingTextMessageCellsForTableView:(UITableView*)tableView
{
    // Also register legacy cells for notice and emotes
    [super registerIncomingTextMessageCellsForTableView:tableView];
    
    [tableView registerClass:TextMessageIncomingBubbleCell.class forCellReuseIdentifier:TextMessageIncomingBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageIncomingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:TextMessageIncomingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageIncomingWithoutSenderNameBubbleCell.class forCellReuseIdentifier:TextMessageIncomingWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageIncomingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:TextMessageIncomingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
}

- (void)registerOutgoingTextMessageCellsForTableView:(UITableView*)tableView
{
    // Also register legacy cells for notice and emotes
    [super registerOutgoingTextMessageCellsForTableView:tableView];
    
    [tableView registerClass:TextMessageOutgoingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:TextMessageOutgoingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageOutgoingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:TextMessageOutgoingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:TextMessageOutgoingWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:TextMessageOutgoingWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
}

- (void)registerVoiceMessageCellsForTableView:(UITableView*)tableView
{
    // Incoming
    [tableView registerClass:VoiceMessageIncomingBubbleCell.class forCellReuseIdentifier:VoiceMessageIncomingBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:VoiceMessageIncomingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:VoiceMessageIncomingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:VoiceMessageIncomingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:VoiceMessageIncomingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    // Outgoing
    [tableView registerClass:VoiceMessageOutgoingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:VoiceMessageOutgoingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:VoiceMessageOutgoingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:VoiceMessageOutgoingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerPollCellsForTableView:(UITableView *)tableView
{
    // Incoming
    [tableView registerClass:PollIncomingBubbleCell.class forCellReuseIdentifier:PollIncomingBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:PollIncomingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:PollIncomingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:PollIncomingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:PollIncomingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    // Outgoing
    [tableView registerClass:PollOutgoingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:PollOutgoingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:PollOutgoingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:PollOutgoingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerLocationCellsForTableView:(UITableView*)tableView
{
    // Incoming
    [tableView registerClass:LocationIncomingBubbleCell.class forCellReuseIdentifier:LocationIncomingBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:LocationIncomingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:LocationIncomingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:LocationIncomingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:LocationIncomingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    // Outgoing
    [tableView registerClass:LocationOutgoingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:LocationOutgoingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:LocationOutgoingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:LocationOutgoingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerFileWithoutThumbnailCellsForTableView:(UITableView*)tableView
{
    // Incoming
    [tableView registerClass:FileWithoutThumbnailIncomingBubbleCell.class forCellReuseIdentifier:FileWithoutThumbnailIncomingBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:FileWithoutThumbnailIncomingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:FileWithoutThumbnailIncomingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:FileWithoutThumbnailIncomingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:FileWithoutThumbnailIncomingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    // Outgoing
    [tableView registerClass:FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:FileWithoutThumbnailOutoingWithPaginationTitleBubbleCell.class forCellReuseIdentifier:FileWithoutThumbnailOutoingWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

#pragma mark - Mapping

- (NSDictionary<NSNumber*, Class>*)incomingTextMessageCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingTextMessage) : TextMessageIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderInfo) : TextMessageIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitle) : TextMessageIncomingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderName) : TextMessageIncomingWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitleWithoutSenderName) : TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingTextMessageEncrypted) : TextMessageIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderInfo) : TextMessageIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitle) : TextMessageIncomingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderName) : TextMessageIncomingWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitleWithoutSenderName) : TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingTextMessageCellsMapping
{
    // Hide sender info and avatar for bubble outgoing messages
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingTextMessage) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderInfo) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitle) : TextMessageOutgoingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderName) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitleWithoutSenderName) : TextMessageOutgoingWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncrypted) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderInfo) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitle) : TextMessageOutgoingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderName) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitleWithoutSenderName) : TextMessageOutgoingWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)incomingEmoteCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingEmote) : TextMessageIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithoutSenderInfo) : TextMessageIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitle) : TextMessageIncomingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithoutSenderName) : TextMessageIncomingWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitleWithoutSenderName) : TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingEmoteEncrypted) : TextMessageIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderInfo) : TextMessageIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitle) : TextMessageIncomingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderName) : TextMessageIncomingWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitleWithoutSenderName) : TextMessageIncomingWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingEmoteCellsMapping
{
    // Hide sender info and avatar for bubble outgoing messages
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingEmote) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderInfo) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitle) : TextMessageOutgoingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderName) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitleWithoutSenderName) : TextMessageOutgoingWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingEmoteEncrypted) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderInfo) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitle) : TextMessageOutgoingWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderName) : TextMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitleWithoutSenderName) : TextMessageOutgoingWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentCellsMapping
{
    // Hide sender info and avatar for bubble outgoing file attachment
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingAttachment) : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutSenderInfo) : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithPaginationTitle) : RoomOutgoingAttachmentWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncrypted) : RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithPaginationTitle) : RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)incomingAttachmentWithoutThumbnailCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnail) : FileWithoutThumbnailIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithoutSenderInfo) : FileWithoutThumbnailIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithPaginationTitle) : FileWithoutThumbnailIncomingWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncrypted) : FileWithoutThumbnailIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo) : FileWithoutThumbnailIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithPaginationTitle) : FileWithoutThumbnailIncomingWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentWithoutThumbnailCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnail) : FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithoutSenderInfo) : FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithPaginationTitle) : FileWithoutThumbnailOutoingWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncrypted) : FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo) : FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithPaginationTitle) : FileWithoutThumbnailOutoingWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)voiceMessageCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingVoiceMessage) : VoiceMessageIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingVoiceMessageWithoutSenderInfo) : VoiceMessageIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingVoiceMessageWithPaginationTitle) : VoiceMessageIncomingWithPaginationTitleBubbleCell.class,
        // Outgoing
        @(RoomTimelineCellIdentifierOutgoingVoiceMessage) : VoiceMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingVoiceMessageWithoutSenderInfo) : VoiceMessageOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingVoiceMessageWithPaginationTitle) : VoiceMessageOutgoingWithPaginationTitleBubbleCell.class,
    };
}

- (NSDictionary<NSNumber *,Class> *)pollCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingPoll) : PollIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingPollWithoutSenderInfo) : PollIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingPollWithPaginationTitle) : PollIncomingWithPaginationTitleBubbleCell.class,
        // Outgoing
        @(RoomTimelineCellIdentifierOutgoingPoll) : PollOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingPollWithoutSenderInfo) : PollOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingPollWithPaginationTitle) : PollOutgoingWithPaginationTitleBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)locationCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingLocation) : LocationIncomingBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingLocationWithoutSenderInfo) : LocationIncomingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingLocationWithPaginationTitle) : LocationIncomingWithPaginationTitleBubbleCell.class,
        // Outgoing
        @(RoomTimelineCellIdentifierOutgoingLocation) : LocationOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingLocationWithoutSenderInfo) : LocationOutgoingWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingLocationWithPaginationTitle) : LocationOutgoingWithPaginationTitleBubbleCell.class
    };
}

@end
