//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PollHistoryDetailViewModelType = StateStoreViewModel<PollHistoryDetailViewState, PollHistoryDetailViewAction>

class PollHistoryDetailViewModel: PollHistoryDetailViewModelType, PollHistoryDetailViewModelProtocol {
    // MARK: Public

    var completion: PollHistoryDetailViewModelCallback?
    
    // MARK: - Setup
    
    init(poll: TimelinePollDetails) {
        super.init(initialViewState: PollHistoryDetailViewState(poll: poll))
    }
    
    // MARK: - Public
    
    override func process(viewAction: PollHistoryDetailViewAction) {
        switch viewAction {
        case .dismiss:
            completion?(.dismiss)
        case .viewInTimeline:
            completion?(.viewInTimeline)
        }
    }
}
