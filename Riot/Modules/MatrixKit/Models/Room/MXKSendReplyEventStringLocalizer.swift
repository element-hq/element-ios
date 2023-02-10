// 
// Copyright 2022 New Vector Ltd
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
