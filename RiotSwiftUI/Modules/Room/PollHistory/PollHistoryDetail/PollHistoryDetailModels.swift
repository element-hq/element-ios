//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

// MARK: - Coordinator

typealias PollHistoryDetailViewModelCallback = (PollHistoryDetailViewModelResult) -> Void

enum PollHistoryDetailViewModelResult {
    case dismiss
    case viewInTimeline
}

// MARK: View

struct PollHistoryDetailViewState: BindableState {
    var poll: TimelinePollDetails
    var pollStartDate: Date {
        poll.startDate
    }

    var isPollClosed: Bool {
        poll.closed
    }
}

enum PollHistoryDetailViewAction {
    case dismiss
    case viewInTimeline
}
