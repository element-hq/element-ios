// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    RoomTimelineCellIdentifierMatrixRTCCall,
    
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
