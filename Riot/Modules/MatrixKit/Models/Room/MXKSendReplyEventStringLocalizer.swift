// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MXKSendReplyEventStringLocalizer: NSObject, MXSendReplyEventStringLocalizerProtocol {
    func senderSentAnImage() -> String {
        VectorL10n.messageReplyToSenderSentAnImage
    }

    func senderSentAVideo() -> String {
        VectorL10n.messageReplyToSenderSentAVideo
    }

    func senderSentAnAudioFile() -> String {
        VectorL10n.messageReplyToSenderSentAnAudioFile
    }

    func senderSentAVoiceMessage() -> String {
        VectorL10n.messageReplyToSenderSentAVoiceMessage
    }

    func senderSentAFile() -> String {
        VectorL10n.messageReplyToSenderSentAFile
    }

    func senderSentTheirLocation() -> String {
        VectorL10n.messageReplyToSenderSentTheirLocation
    }
    
    func senderSentTheirLiveLocation() -> String {
        VectorL10n.messageReplyToSenderSentTheirLiveLocation
    }

    func messageToReplyToPrefix() -> String {
        VectorL10n.messageReplyToMessageToReplyToPrefix
    }
    
    func endedPollMessage() -> String {
        VectorL10n.pollTimelineReplyEndedPoll
    }
}
