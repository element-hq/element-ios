/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

enum RoomReactionsViewAction {
    case loadData
    case tapReaction(index: Int)
    case addNewReaction
    case tapShowAction(action: ShowAction)
    case longPress

    enum ShowAction {
        case showAll
        case showLess
        case addReaction
    }
}

enum RoomReactionsViewState {
    case loaded(reactionsViewData: [RoomReactionViewData], remainingViewData: [RoomReactionViewData], showAllButtonState: ShowAllButtonState, showAddReaction: Bool)

    enum ShowAllButtonState {
        case none
        case showAll
        case showLess
    }
}

@objc protocol RoomReactionsViewModelDelegate: AnyObject {
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didAddReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didRemoveReaction reactionCount: MXReactionCount, forEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didShowAllTappedForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didShowLessTappedForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didTapAddReactionForEventId eventId: String)
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didLongPressForEventId eventId: String)
}

protocol RoomReactionsViewModelViewDelegate: AnyObject {
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didUpdateViewState viewState: RoomReactionsViewState)
}

protocol RoomReactionsViewModelType {
    var viewModelDelegate: RoomReactionsViewModelDelegate? { get set }
    var viewDelegate: RoomReactionsViewModelViewDelegate? { get set }
    
    func process(viewAction: RoomReactionsViewAction)
}
