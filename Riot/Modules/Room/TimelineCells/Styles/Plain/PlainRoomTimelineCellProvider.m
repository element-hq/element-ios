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

#import "PlainRoomTimelineCellProvider.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import "RoomEmptyBubbleCell.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomIncomingEncryptedTextMsgBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleWithoutSenderNameBubbleCell.h"

#import "RoomOutgoingEncryptedTextMsgBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomMembershipBubbleCell.h"
#import "RoomMembershipWithPaginationTitleBubbleCell.h"
#import "RoomMembershipCollapsedBubbleCell.h"
#import "RoomMembershipCollapsedWithPaginationTitleBubbleCell.h"
#import "RoomMembershipExpandedBubbleCell.h"
#import "RoomMembershipExpandedWithPaginationTitleBubbleCell.h"
#import "RoomCreationWithPaginationCollapsedBubbleCell.h"
#import "RoomCreationCollapsedBubbleCell.h"

#import "RoomSelectedStickerBubbleCell.h"
#import "RoomPredecessorBubbleCell.h"

#import "GeneratedInterface-Swift.h"

@interface PlainRoomTimelineCellProvider()

@property (nonatomic, strong) NSDictionary<NSNumber*, Class>* cellClasses;

@end

@implementation PlainRoomTimelineCellProvider

#pragma mark - Public

- (void)registerCellsForTableView:(UITableView*)tableView
{
    // Text message
    
    [self registerIncomingTextMessageCellsForTableView:tableView];
    
    [self registerOutgoingTextMessageCellsForTableView:tableView];

    // Attachment cells
    
    [self registerIncomingAttachmentCellsForTableView:tableView];

    [self registerOutgoingAttachmentCellsForTableView:tableView];

    // Other cells
    
    [self registerMembershipCellsForTableView:tableView];
        
    [self registerKeyVerificationCellsForTableView:tableView];
    
    [self registerRoomCreationCellsForTableView:tableView];
        
    [self registerCallCellsForTableView:tableView];
        
    [self registerVoiceMessageCellsForTableView:tableView];
    
    [self registerPollCellsForTableView:tableView];
    
    [self registerLocationCellsForTableView:tableView];
        
    [tableView registerClass:RoomEmptyBubbleCell.class forCellReuseIdentifier:RoomEmptyBubbleCell.defaultReuseIdentifier];
    
    [tableView registerClass:RoomSelectedStickerBubbleCell.class forCellReuseIdentifier:RoomSelectedStickerBubbleCell.defaultReuseIdentifier];
    
    [tableView registerClass:RoomPredecessorBubbleCell.class forCellReuseIdentifier:RoomPredecessorBubbleCell.defaultReuseIdentifier];
    
    [tableView registerClass:RoomCreationIntroCell.class forCellReuseIdentifier:RoomCreationIntroCell.defaultReuseIdentifier];
    
    [tableView registerNib:RoomTypingBubbleCell.nib forCellReuseIdentifier:RoomTypingBubbleCell.defaultReuseIdentifier];
}

- (Class<MXKCellRendering>)cellViewClassForCellIdentifier:(RoomTimelineCellIdentifier)identifier
{
    if (self.cellClasses == nil)
    {
        self.cellClasses = [self buildCellClasses];
    }
    
    Class cellViewClass = self.cellClasses[@(identifier)];
    
    
    return cellViewClass;
}

#pragma mark - Private

#pragma mark Cell registration

- (void)registerIncomingTextMessageCellsForTableView:(UITableView*)tableView
{
    // Clear
    
    [tableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    // Encrypted
    
    [tableView registerClass:RoomIncomingEncryptedTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
}

- (void)registerOutgoingTextMessageCellsForTableView:(UITableView*)tableView
{
    // Clear
    
    [tableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    // Encrypted
    
    [tableView registerClass:RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
}

- (void)registerIncomingAttachmentCellsForTableView:(UITableView*)tableView
{
    // Clear
    
    [tableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    // Encrypted
    
    [tableView registerClass:RoomIncomingEncryptedAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerOutgoingAttachmentCellsForTableView:(UITableView*)tableView
{
    // Clear
    
    [tableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingAttachmentWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    // Encrypted
    
    [tableView registerClass:RoomOutgoingEncryptedAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
}

- (void)registerMembershipCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:RoomMembershipBubbleCell.class forCellReuseIdentifier:RoomMembershipBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomMembershipWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomMembershipCollapsedBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomMembershipCollapsedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomMembershipExpandedBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomMembershipExpandedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerKeyVerificationCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:KeyVerificationIncomingRequestApprovalBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:KeyVerificationRequestStatusBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:KeyVerificationConclusionBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:KeyVerificationConclusionWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerRoomCreationCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:RoomCreationCollapsedBubbleCell.class forCellReuseIdentifier:RoomCreationCollapsedBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomCreationWithPaginationCollapsedBubbleCell.class forCellReuseIdentifier:RoomCreationWithPaginationCollapsedBubbleCell.defaultReuseIdentifier];
}

- (void)registerCallCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:RoomDirectCallStatusBubbleCell.class forCellReuseIdentifier:RoomDirectCallStatusBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:RoomGroupCallStatusBubbleCell.class forCellReuseIdentifier:RoomGroupCallStatusBubbleCell.defaultReuseIdentifier];
}

- (void)registerVoiceMessageCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:VoiceMessageBubbleCell.class forCellReuseIdentifier:VoiceMessageBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:VoiceMessageWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:VoiceMessageWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:VoiceMessageWithPaginationTitleBubbleCell.class forCellReuseIdentifier:VoiceMessageWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerPollCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:PollBubbleCell.class forCellReuseIdentifier:PollBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:PollWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:PollWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:PollWithPaginationTitleBubbleCell.class forCellReuseIdentifier:PollWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

- (void)registerLocationCellsForTableView:(UITableView*)tableView
{
    [tableView registerClass:LocationBubbleCell.class forCellReuseIdentifier:LocationBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:LocationWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:LocationWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [tableView registerClass:LocationWithPaginationTitleBubbleCell.class forCellReuseIdentifier:LocationWithPaginationTitleBubbleCell.defaultReuseIdentifier];
}

#pragma mark Cell class association

- (NSDictionary<NSNumber*, Class>*)buildCellClasses
{
    NSMutableDictionary<NSNumber*, Class>* cellClasses = [NSMutableDictionary dictionary];
    
    // Text message
    
    NSDictionary *incomingTextMessageCellsMapping = [self incomingTextMessageCellsMapping];
    [cellClasses addEntriesFromDictionary:incomingTextMessageCellsMapping];
    
    NSDictionary *outgoingTextMessageCellsMapping = [self outgoingTextMessageCellsMapping];
    [cellClasses addEntriesFromDictionary:outgoingTextMessageCellsMapping];
    
    // Emote
    NSDictionary *incomingEmoteCellsMapping = [self incomingEmoteCellsMapping];
    [cellClasses addEntriesFromDictionary:incomingEmoteCellsMapping];
    
    NSDictionary *outgoingEmoteCellsMapping = [self outgoingEmoteCellsMapping];
    [cellClasses addEntriesFromDictionary:outgoingEmoteCellsMapping];
    
    // Attachment
    
    NSDictionary *incomingAttachmentCellsMapping = [self incomingAttachmentCellsMapping];
    [cellClasses addEntriesFromDictionary:incomingAttachmentCellsMapping];
    
    NSDictionary *outgoingAttachmentCellsMapping = [self outgoingAttachmentCellsMapping];
    [cellClasses addEntriesFromDictionary:outgoingAttachmentCellsMapping];
    
    NSDictionary *outgoingAttachmentWithoutThumbnailCellsMapping = [self outgoingAttachmentWithoutThumbnailCellsMapping];
    [cellClasses addEntriesFromDictionary:outgoingAttachmentWithoutThumbnailCellsMapping];
    
    NSDictionary *incomingAttachmentWithoutThumbnailCellsMapping = [self incomingAttachmentWithoutThumbnailCellsMapping];
    [cellClasses addEntriesFromDictionary:incomingAttachmentWithoutThumbnailCellsMapping];
    
    // Other cells
    
    NSDictionary *roomMembershipCellsMapping = [self membershipCellsMapping];
    [cellClasses addEntriesFromDictionary:roomMembershipCellsMapping];
    
    NSDictionary *keyVerificationCellsMapping = [self keyVerificationCellsMapping];
    [cellClasses addEntriesFromDictionary:keyVerificationCellsMapping];
    
    NSDictionary *roomCreationCellsMapping = [self roomCreationCellsMapping];
    [cellClasses addEntriesFromDictionary:roomCreationCellsMapping];
    
    NSDictionary *callCellsMapping = [self callCellsMapping];
    [cellClasses addEntriesFromDictionary:callCellsMapping];

    NSDictionary *voiceMessageCellsMapping = [self voiceMessageCellsMapping];
    [cellClasses addEntriesFromDictionary:voiceMessageCellsMapping];

    NSDictionary *pollCellsMapping = [self pollCellsMapping];
    [cellClasses addEntriesFromDictionary:pollCellsMapping];
    
    NSDictionary *locationCellsMapping = [self locationCellsMapping];
    [cellClasses addEntriesFromDictionary:locationCellsMapping];
        
    NSDictionary *othersCells = @{
        @(RoomTimelineCellIdentifierEmpty) : RoomEmptyBubbleCell.class,
        @(RoomTimelineCellIdentifierSelectedSticker) : RoomSelectedStickerBubbleCell.class,
        @(RoomTimelineCellIdentifierRoomPredecessor) : RoomPredecessorBubbleCell.class,
        @(RoomTimelineCellIdentifierRoomCreationIntro) : RoomCreationIntroCell.class,
        @(RoomTimelineCellIdentifierTyping) : RoomTypingBubbleCell.class,
    };
    [cellClasses addEntriesFromDictionary:othersCells];

    return [cellClasses copy];
}

- (NSDictionary<NSNumber*, Class>*)incomingTextMessageCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingTextMessage) : RoomIncomingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderInfo) : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitle) : RoomIncomingTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderName) : RoomIncomingTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitleWithoutSenderName) : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingTextMessageEncrypted) : RoomIncomingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderInfo) : RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitle) : RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderName) : RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitleWithoutSenderName) : RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingTextMessageCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingTextMessage) : RoomOutgoingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderInfo) : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitle) : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderName) : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitleWithoutSenderName) : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncrypted) : RoomOutgoingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitle) : RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitleWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)incomingEmoteCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingEmote) : RoomIncomingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithoutSenderInfo) : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitle) : RoomIncomingTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithoutSenderName) : RoomIncomingTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitleWithoutSenderName) : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingEmoteEncrypted) : RoomIncomingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderInfo) : RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitle) : RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderName) : RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitleWithoutSenderName) : RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingEmoteCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingEmote) : RoomOutgoingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderInfo) : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitle) : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderName) : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitleWithoutSenderName) : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingEmoteEncrypted) : RoomOutgoingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitle) : RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitleWithoutSenderName) : RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)incomingAttachmentCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingAttachment) : RoomIncomingAttachmentBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutSenderInfo) : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithPaginationTitle) : RoomIncomingAttachmentWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingAttachmentEncrypted) : RoomIncomingEncryptedAttachmentBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithoutSenderInfo) : RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithPaginationTitle) : RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingAttachment) : RoomOutgoingAttachmentBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutSenderInfo) : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithPaginationTitle) : RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncrypted) : RoomOutgoingEncryptedAttachmentBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithPaginationTitle) : RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)incomingAttachmentWithoutThumbnailCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnail) : RoomIncomingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithoutSenderInfo) : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithPaginationTitle) : RoomIncomingTextMsgWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncrypted) : RoomIncomingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo) : RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithPaginationTitle) : RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentWithoutThumbnailCellsMapping
{
    return @{
        // Clear
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnail) : RoomOutgoingTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithoutSenderInfo) : RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithPaginationTitle) : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class,
        // Encrypted
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncrypted) : RoomOutgoingEncryptedTextMsgBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo) : RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithPaginationTitle) : RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)membershipCellsMapping
{
    return @{
        @(RoomTimelineCellIdentifierMembership) : RoomMembershipBubbleCell.class,
        @(RoomTimelineCellIdentifierMembershipWithPaginationTitle) : RoomMembershipWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierMembershipCollapsed) : RoomMembershipCollapsedBubbleCell.class,
        @(RoomTimelineCellIdentifierMembershipCollapsedWithPaginationTitle) : RoomMembershipCollapsedWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierMembershipExpanded) : RoomMembershipExpandedBubbleCell.class,
        @(RoomTimelineCellIdentifierMembershipExpandedWithPaginationTitle) : RoomMembershipExpandedWithPaginationTitleBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)keyVerificationCellsMapping
{
    return @{
        @(RoomTimelineCellIdentifierKeyVerificationIncomingRequestApproval) : KeyVerificationIncomingRequestApprovalBubbleCell.class,
        @(RoomTimelineCellIdentifierKeyVerificationIncomingRequestApprovalWithPaginationTitle) : KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierKeyVerificationRequestStatus) : KeyVerificationRequestStatusBubbleCell.class,
        @(RoomTimelineCellIdentifierKeyVerificationRequestStatusWithPaginationTitle) : KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class,
        @(RoomTimelineCellIdentifierKeyVerificationConclusion) : KeyVerificationConclusionBubbleCell.class,
        @(RoomTimelineCellIdentifierKeyVerificationConclusionWithPaginationTitle) : KeyVerificationConclusionWithPaginationTitleBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)roomCreationCellsMapping
{
    return @{
        @(RoomTimelineCellIdentifierRoomCreationCollapsed) : RoomCreationCollapsedBubbleCell.class,
        @(RoomTimelineCellIdentifierRoomCreationCollapsedWithPaginationTitle) : RoomCreationWithPaginationCollapsedBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)callCellsMapping
{
    return @{
        @(RoomTimelineCellIdentifierDirectCallStatus) : RoomDirectCallStatusBubbleCell.class,
        @(RoomTimelineCellIdentifierGroupCallStatus) : RoomGroupCallStatusBubbleCell.class,
    };
}

- (NSDictionary<NSNumber*, Class>*)voiceMessageCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingVoiceMessage) : VoiceMessageBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingVoiceMessageWithoutSenderInfo) : VoiceMessageWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingVoiceMessageWithPaginationTitle) : VoiceMessageWithPaginationTitleBubbleCell.class,
        // Outoing
        @(RoomTimelineCellIdentifierOutgoingVoiceMessage) : VoiceMessageBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingVoiceMessageWithoutSenderInfo) : VoiceMessageWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingVoiceMessageWithPaginationTitle) : VoiceMessageWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)pollCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingPoll) : PollBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingPollWithoutSenderInfo) : PollWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingPollWithPaginationTitle) : PollWithPaginationTitleBubbleCell.class,
        // Outoing
        @(RoomTimelineCellIdentifierOutgoingPoll) : PollBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingPollWithoutSenderInfo) : PollWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingPollWithPaginationTitle) : PollWithPaginationTitleBubbleCell.class
    };
}

- (NSDictionary<NSNumber*, Class>*)locationCellsMapping
{
    return @{
        // Incoming
        @(RoomTimelineCellIdentifierIncomingLocation) : LocationBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingLocationWithoutSenderInfo) : LocationWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierIncomingLocationWithPaginationTitle) : LocationWithPaginationTitleBubbleCell.class,
        // Outgoing
        @(RoomTimelineCellIdentifierOutgoingLocation) : LocationBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingLocationWithoutSenderInfo) : LocationWithoutSenderInfoBubbleCell.class,
        @(RoomTimelineCellIdentifierOutgoingLocationWithPaginationTitle) : LocationWithPaginationTitleBubbleCell.class
    };
}


@end
