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

import Foundation

// MARK:  -Events

extension AnalyticsEvent.Error: DictionaryConvertible { }
extension AnalyticsEvent.CallStarted: DictionaryConvertible { }
extension AnalyticsEvent.CallEnded: DictionaryConvertible { }
extension AnalyticsEvent.CallError: DictionaryConvertible { }

// MARK: - Enums

extension AnalyticsEvent.ErrorDomain: CustomStringConvertible {
    var description: String { rawValue }
}

extension AnalyticsEvent.ErrorName: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - Helpers

extension __MXCallHangupReason {
    var errorName: AnalyticsEvent.ErrorName {
        switch self {
        case .userHangup:
            return .VoipUserHangup
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
            return .UnknownError
        }
    }
}

extension DecryptionFailureReason {
    var errorName: AnalyticsEvent.ErrorName {
        switch self {
        case .unspecified:
            return .OlmUnspecifiedError
        case .olmKeysNotSent:
            return .OlmKeysNotSentError
        case .olmIndexError:
            return .OlmIndexError
        case .unexpected:
            return .UnknownError
        default:
            return .UnknownError
        }
    }
}
