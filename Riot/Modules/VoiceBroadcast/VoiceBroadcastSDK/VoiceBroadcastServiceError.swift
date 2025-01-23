// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// VoiceBroadcastService error
public enum VoiceBroadcastServiceError: Int, Error {
    case missingUserId
    case roomNotFound
    case notStarted
    case unexpectedState
    case unknown
}

// MARK: - VoiceBroadcastService errors
extension VoiceBroadcastServiceError: CustomNSError {
    public static let errorDomain = "io.element.voice_broadcast_info"

    public var errorCode: Int {
        return Int(rawValue)
    }

    public var errorUserInfo: [String: Any] {
        return [:]
    }
}
