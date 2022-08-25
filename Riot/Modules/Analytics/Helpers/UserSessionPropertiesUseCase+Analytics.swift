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
import Foundation

extension UserSessionProperties.UseCase {
    var analyticsName: AnalyticsEvent.UserProperties.FtueUseCaseSelection {
        switch self {
        case .personalMessaging:
            return .PersonalMessaging
        case .workMessaging:
            return .WorkMessaging
        case .communityMessaging:
            return .CommunityMessaging
        case .skipped:
            return .Skip
        }
    }
}
