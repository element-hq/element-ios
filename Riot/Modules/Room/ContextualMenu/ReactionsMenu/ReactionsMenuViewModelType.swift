/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ReactionsMenuViewModelViewDelegate: AnyObject {
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didUpdateViewState viewState: ReactionsMenuViewState)
}

@objc protocol ReactionsMenuViewModelCoordinatorDelegate: AnyObject {
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didAddReaction reaction: String, forEventId eventId: String)
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didRemoveReaction reaction: String, forEventId eventId: String)
    func reactionsMenuViewModelDidTapMoreReactions(_ viewModel: ReactionsMenuViewModel, forEventId eventId: String)
}

protocol ReactionsMenuViewModelType {
    
    var coordinatorDelegate: ReactionsMenuViewModelCoordinatorDelegate? { get set }
    var viewDelegate: ReactionsMenuViewModelViewDelegate? { get set }
    
    func process(viewAction: ReactionsMenuViewAction)
}
