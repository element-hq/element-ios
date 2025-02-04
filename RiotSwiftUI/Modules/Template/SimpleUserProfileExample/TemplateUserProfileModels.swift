//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
