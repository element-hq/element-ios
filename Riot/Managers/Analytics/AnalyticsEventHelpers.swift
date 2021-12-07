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

// MARK: - Helpers

extension MXTaskProfileName {
    var analyticsName: AnalyticsEvent.PerformanceTimer.Name? {
        switch self {
        case .startupIncrementalSync:
            return .StartupIncrementalSync
        case .startupInitialSync:
            return .StartupInitialSync
        case .startupLaunchScreen:
            return .StartupLaunchScreen
        case .startupStorePreload:
            return .StartupStorePreload
        case .startupMountData:
            return .StartupStoreReady
        case .initialSyncRequest:
            return .InitialSyncRequest
        case .initialSyncParsing:
            return .InitialSyncParsing
        case .notificationsOpenEvent:
            return .NotificationsOpenEvent
        default:
            return nil
        }
    }
}

extension __MXCallHangupReason {
    var errorName: AnalyticsEvent.Error.Name {
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
        default:
            return .UnknownError
        }
    }
}

extension AnalyticsEvent.JoinedRoom.RoomSize {
    init?(memberCount: UInt) {
        switch memberCount {
        case 2:
            self = .Two
        case 3...10:
            self = .ThreeToTen
        case 11...100:
            self = .ElevenToOneHundred
        case 101...1000:
            self = .OneHundredAndOneToAThousand
        case 1001...:
            self = .MoreThanAThousand
        default:
            return nil
        }
    }
}
