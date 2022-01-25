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

- (NSDictionary<NSNumber*, Class>*)outgoingTextMessageCellsMapping
{
    // Hide sender info and avatar for bubble outgoing messages
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingTextMessage) : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderInfo) : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitle) : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderName) : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitleWithoutSenderName) : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncrypted) : RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitle) : RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitleWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
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
