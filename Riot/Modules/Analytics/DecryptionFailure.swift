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

import AnalyticsEvents

/// Failure reasons as defined in https://docs.google.com/document/d/1es7cTCeJEXXfRCTRgZerAM2Wg5ZerHjvlpfTW-gsOfI.
@objc enum DecryptionFailureReason: Int {
    case unspecified
    case olmKeysNotSent
    case olmIndexError
    case unexpected
    
    var errorName: AnalyticsEvent.Error.Name {
        switch self {
        case .unspecified:
            return .OlmUnspecifiedError
        case .olmKeysNotSent:
            return .OlmKeysNotSentError
        case .olmIndexError:
            return .OlmIndexError
        case .unexpected:
            return .UnknownError
        }
    }
}

/// `DecryptionFailure` represents a decryption failure.
@objcMembers class DecryptionFailure: NSObject {
    /// The id of the event that was unabled to decrypt.
    let failedEventId: String
    /// The time the failure has been reported.
    let ts: TimeInterval = Date().timeIntervalSince1970
    /// Decryption failure reason.
    let reason: DecryptionFailureReason
    /// Additional context of failure
    let context: String
    
    init(failedEventId: String, reason: DecryptionFailureReason, context: String) {
        self.failedEventId = failedEventId
        self.reason = reason
        self.context = context
    }
}
