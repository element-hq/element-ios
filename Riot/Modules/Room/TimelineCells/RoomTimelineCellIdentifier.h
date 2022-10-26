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

/// RoomTimelineCellIdentifier represents room timeline cell identifiers.
typedef NS_ENUM(NSUInteger, RoomTimelineCellIdentifier) {
    
    RoomTimelineCellIdentifierUnknown,
    
    // - Text message
    // -- Incoming
    // --- Clear
    RoomTimelineCellIdentifierIncomingTextMessage,
    RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitle,
    RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderName,
    RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitleWithoutSenderName,
    // --- Encrypted
    RoomTimelineCellIdentifierIncomingTextMessageEncrypted,
    RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitle,
    RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderName,
    RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitleWithoutSenderName,
    // -- Outgoing
    // --- Clear
    RoomTimelineCellIdentifierOutgoingTextMessage,
    RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitle,
    RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderName,
    RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitleWithoutSenderName,
    // --- Encrypted
    RoomTimelineCellIdentifierOutgoingTextMessageEncrypted,
    RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitle,
    RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderName,
    RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitleWithoutSenderName,
    
    // - Emote
    // -- Incoming
    // --- Clear
    RoomTimelineCellIdentifierIncomingEmote,
    RoomTimelineCellIdentifierIncomingEmoteWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitle,
    RoomTimelineCellIdentifierIncomingEmoteWithoutSenderName,
    RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitleWithoutSenderName,
    // --- Encrypted
    RoomTimelineCellIdentifierIncomingEmoteEncrypted,
    RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitle,
    RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderName,
    RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitleWithoutSenderName,
    // -- Outgoing
    // --- Clear
    RoomTimelineCellIdentifierOutgoingEmote,
    RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitle,
    RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderName,
    RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitleWithoutSenderName,
    // --- Encrypted
    RoomTimelineCellIdentifierOutgoingEmoteEncrypted,
    RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitle,
    RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderName,
    RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitleWithoutSenderName,
    
    // - Attachment
    // -- Incoming
    // --- Clear
    RoomTimelineCellIdentifierIncomingAttachment,
    RoomTimelineCellIdentifierIncomingAttachmentWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingAttachmentWithPaginationTitle,
    // --- Encrypted
    RoomTimelineCellIdentifierIncomingAttachmentEncrypted,
    RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithPaginationTitle,
    // -- Outgoing
    // --- Clear
    RoomTimelineCellIdentifierOutgoingAttachment,
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingAttachmentWithPaginationTitle,
    // --- Encrypted
    RoomTimelineCellIdentifierOutgoingAttachmentEncrypted,
    RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithPaginationTitle,
    
    // - Attachment without thumbnail
    // --- Clear
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnail,
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithPaginationTitle,
    // --- Encrypted
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncrypted,
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithPaginationTitle,
    // -- Outgoing
    // --- Clear
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnail,
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithPaginationTitle,
    // --- Encrypted
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncrypted,
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithPaginationTitle,
    
    // - Room membership
    RoomTimelineCellIdentifierMembership,
    RoomTimelineCellIdentifierMembershipWithPaginationTitle,
    RoomTimelineCellIdentifierMembershipCollapsed,
    RoomTimelineCellIdentifierMembershipCollapsedWithPaginationTitle,
    RoomTimelineCellIdentifierMembershipExpanded,
    RoomTimelineCellIdentifierMembershipExpandedWithPaginationTitle,
    
    // - Key verification
    RoomTimelineCellIdentifierKeyVerificationIncomingRequestApproval,
    RoomTimelineCellIdentifierKeyVerificationIncomingRequestApprovalWithPaginationTitle,
    RoomTimelineCellIdentifierKeyVerificationRequestStatus,
    RoomTimelineCellIdentifierKeyVerificationRequestStatusWithPaginationTitle,
    RoomTimelineCellIdentifierKeyVerificationConclusion,
    RoomTimelineCellIdentifierKeyVerificationConclusionWithPaginationTitle,
    
    // - Room creation
    RoomTimelineCellIdentifierRoomCreationCollapsed,
    RoomTimelineCellIdentifierRoomCreationCollapsedWithPaginationTitle,
    
    // - Call
    RoomTimelineCellIdentifierDirectCallStatus,
    RoomTimelineCellIdentifierGroupCallStatus,
    
    // - Voice message
    // -- Incoming
    RoomTimelineCellIdentifierIncomingVoiceMessage,
    RoomTimelineCellIdentifierIncomingVoiceMessageWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingVoiceMessageWithPaginationTitle,
    // -- Outgoing
    RoomTimelineCellIdentifierOutgoingVoiceMessage,
    RoomTimelineCellIdentifierOutgoingVoiceMessageWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingVoiceMessageWithPaginationTitle,
    
    // - Poll
    // -- Incoming
    RoomTimelineCellIdentifierIncomingPoll,
    RoomTimelineCellIdentifierIncomingPollWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingPollWithPaginationTitle,
    // -- Outgoing
    RoomTimelineCellIdentifierOutgoingPoll,
    RoomTimelineCellIdentifierOutgoingPollWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingPollWithPaginationTitle,
    
    // - Location sharing
    // -- Incoming
    RoomTimelineCellIdentifierIncomingLocation,
    RoomTimelineCellIdentifierIncomingLocationWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingLocationWithPaginationTitle,
    // -- Outgoing
    RoomTimelineCellIdentifierOutgoingLocation,
    RoomTimelineCellIdentifierOutgoingLocationWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingLocationWithPaginationTitle,
    
    // - Voice broadcast
    // -- Incoming
    RoomTimelineCellIdentifierIncomingVoiceBroadcastPlayback,
    RoomTimelineCellIdentifierIncomingVoiceBroadcastPlaybackWithoutSenderInfo,
    RoomTimelineCellIdentifierIncomingVoiceBroadcastPlaybackWithPaginationTitle,
    // -- Outgoing
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlayback,
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlaybackWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlaybackWithPaginationTitle,
    
    // - Voice broadcast recorder
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorder,
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorderWithoutSenderInfo,
    RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorderWithPaginationTitle,
    
    // - Others
    RoomTimelineCellIdentifierEmpty,
    RoomTimelineCellIdentifierSelectedSticker,
    RoomTimelineCellIdentifierRoomPredecessor,
    RoomTimelineCellIdentifierRoomCreationIntro,
    RoomTimelineCellIdentifierTyping
};
