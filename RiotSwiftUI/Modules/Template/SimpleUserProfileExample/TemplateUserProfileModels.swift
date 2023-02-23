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

// MARK: - Coordinator

enum TemplateUserProfilePresence {
    case online
    case idle
    case offline
}

extension TemplateUserProfilePresence: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .online:
            return VectorL10n.roomParticipantsOnline
        case .idle:
            return VectorL10n.roomParticipantsIdle
        case .offline:
            return VectorL10n.roomParticipantsOffline
        }
    }
}

// MARK: View model

enum TemplateUserProfileViewModelResult {
    case cancel
    case done
}

// MARK: View

struct TemplateUserProfileViewState: BindableState {
    let avatar: AvatarInputProtocol?
    let displayName: String?
    var presence: TemplateUserProfilePresence
    var count: Int
}

enum TemplateUserProfileViewAction {
    case incrementCount
    case decrementCount
    case cancel
    case done
}
