// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

@objc enum DecryptionFailureReason: Int {
    case unspecified
    case olmKeysNotSent
    case olmIndexError
    
    var errorName: AnalyticsEvent.Error.Name {
        switch self {
        case .unspecified:
            return .OlmUnspecifiedError
        case .olmKeysNotSent:
            return .OlmKeysNotSentError
        case .olmIndexError:
            return .OlmIndexError
        }
    }
}

/// `DecryptionFailure` represents a decryption failure.
@objcMembers class DecryptionFailure: NSObject {
    /// The id of the event that was unabled to decrypt.
    let failedEventId: String
    /// The time the failure has been reported.
    let ts: TimeInterval
    /// Decryption failure reason.
    let reason: DecryptionFailureReason
    /// Additional context of failure
    let context: String
    
    /// UTDs can be permanent or temporary. If temporary, this field will contain the time it took to decrypt the message in milliseconds. If permanent should be nil
    var timeToDecrypt: TimeInterval?
    
    /// Was the current cross-signing identity trusted at the time of decryption
    var trustOwnIdentityAtTimeOfFailure: Bool?
    
    var eventLocalAgeMillis: Int?
    
    /// Is the current user on matrix org
    var isMatrixOrg: Bool?
    /// Are the sender and recipient on the same homeserver
    var isFederated: Bool?
    
    /// As for now the ios App only reports UTDs visible to user (error are reported from EventFormatter
    var wasVisibleToUser: Bool = true
    
    init(failedEventId: String, reason: DecryptionFailureReason, context: String, ts: TimeInterval) {
        self.failedEventId = failedEventId
        self.reason = reason
        self.context = context
        self.ts = ts
    }
}
