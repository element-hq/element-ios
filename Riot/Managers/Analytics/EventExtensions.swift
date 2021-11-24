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
import AnalyticsEvents

// MARK: - Events
//
// All events must conform to DictionaryConvertible to be captured by PostHog

extension AnalyticsEventError: DictionaryConvertible { }
extension AnalyticsEventCallStarted: DictionaryConvertible { }
extension AnalyticsEventCallEnded: DictionaryConvertible { }
extension AnalyticsEventCallError: DictionaryConvertible { }
extension AnalyticsEventScreen: DictionaryConvertible { }

// MARK: - Enums
//
// All enums must conform to CustomStringConvertible for DictionaryConvertible to access the raw value

extension AnalyticsEventErrorDomain: CustomStringConvertible {
    public var description: String { rawValue }
}

extension AnalyticsEventErrorName: CustomStringConvertible {
    public var description: String { rawValue }
}

extension AnalyticsEventScreenName: CustomStringConvertible {
    public var description: String { rawValue }
}

// MARK: - Helpers

extension __MXCallHangupReason {
    var errorName: AnalyticsEventErrorName {
        switch self {
        case .userHangup:
            return .voipUserHangup
        case .inviteTimeout:
            return .voipInviteTimeout
        case .iceFailed:
            return .voipIceFailed
        case .iceTimeout:
            return .voipIceTimeout
        case .userMediaFailed:
            return .voipUserMediaFailed
        case .unknownError:
            return .unknownError
        default:
            return .unknownError
        }
    }
}

extension DecryptionFailureReason {
    var errorName: AnalyticsEventErrorName {
        switch self {
        case .unspecified:
            return .olmUnspecifiedError
        case .olmKeysNotSent:
            return .olmKeysNotSentError
        case .olmIndexError:
            return .olmIndexError
        case .unexpected:
            return .unknownError
        default:
            return .unknownError
        }
    }
}
