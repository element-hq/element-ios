// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EditHistoryViewModelViewDelegate: AnyObject {
    func editHistoryViewModel(_ viewModel: EditHistoryViewModelType, didUpdateViewState viewSate: EditHistoryViewState)
}

protocol EditHistoryViewModelCoordinatorDelegate: AnyObject {
    func editHistoryViewModelDidClose(_ viewModel: EditHistoryViewModelType)
}

/// Protocol describing the view model used by `EditHistoryViewController`
protocol EditHistoryViewModelType {
        
    var viewDelegate: EditHistoryViewModelViewDelegate? { get set }
    var coordinatorDelegate: EditHistoryViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EditHistoryViewAction)
}
