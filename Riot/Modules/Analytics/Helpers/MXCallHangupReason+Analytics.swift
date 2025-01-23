// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

extension __MXCallHangupReason {
    var errorName: AnalyticsEvent.Error.Name {
        switch self {
        case .userHangup:
            return .VoipUserHangup
        case .userBusy:
            // There is no dedicated analytics event for `userBusy` error
            return .UnknownError
        case .inviteTimeout:
            return .VoipInviteTimeout
        case .iceFailed:
            return .VoipIceFailed
        case .iceTimeout:
            return .VoipIceTimeout
        case .userMediaFailed:
            return .VoipUserMediaFailed
        case .unknownError:
            return .UnknownError
        default:
            MXLog.failure("Unknown or unhandled hangup reason", context: [
                "reason": rawValue
            ])
            return .UnknownError
        }
    }
}
