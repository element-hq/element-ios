//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// MARK: View model

enum PollHistoryConstants {
    static let chunkSizeInDays: UInt = 30
}

enum PollHistoryViewModelResult {
    case showPollDetail(poll: TimelinePollDetails)
}

// MARK: View

enum PollHistoryMode: CaseIterable {
    case active
    case past
}

struct PollHistoryViewBindings {
    var mode: PollHistoryMode
    var alertInfo: AlertInfo<Bool>?
}

struct PollHistoryViewState: BindableState {
    init(mode: PollHistoryMode) {
        bindings = .init(mode: mode)
    }
    
    var bindings: PollHistoryViewBindings
    var isLoading = false
    var canLoadMoreContent = true
    var polls: [TimelinePollDetails]?
    var syncStartDate: Date = .init()
    var syncedUpTo: Date = .distantFuture
}

enum PollHistoryViewAction {
    case viewAppeared
    case segmentDidChange
    case showPollDetail(poll: TimelinePollDetails)
    case loadMoreContent
}
