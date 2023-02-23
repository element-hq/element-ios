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

enum UserOtherSessionsFilter: Identifiable, Equatable, CaseIterable {
    var id: Self { self }
    case all
    case verified
    case unverified
    case inactive
}

extension UserOtherSessionsFilter {
    var menuLocalizedName: String {
        switch self {
        case .all:
            return VectorL10n.userOtherSessionFilterMenuAll
        case .verified:
            return VectorL10n.userOtherSessionFilterMenuVerified
        case .unverified:
            return VectorL10n.userOtherSessionFilterMenuUnverified
        case .inactive:
            return VectorL10n.userOtherSessionFilterMenuInactive
        }
    }
}
